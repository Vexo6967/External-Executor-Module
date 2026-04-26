#pragma once
#include <Windows.h>
#include <thread>
#include <atomic>
#include <cstdio>

class TPHandler {
public:
    TPHandler(DWORD processId, uintptr_t baseAddress)
        : m_pid(processId), m_base(baseAddress) {
    }

    ~TPHandler() {
        stop();
    }

    void start() {
        if (m_running.exchange(true)) return;
        m_worker = std::thread(&TPHandler::scanLoop, this);
    }

    void stop() {
        m_running = false;
        if (m_worker.joinable())
            m_worker.join();
    }

private:
    static constexpr SIZE_T    SCAN_SIZE = 0x1000;
    static constexpr uintptr_t RANGE_LIMIT = 0x50000000;
    static constexpr DWORD     SCAN_INTERVAL = 1000;

    DWORD             m_pid;
    uintptr_t         m_base;
    std::thread       m_worker;
    std::atomic<bool> m_running{ false };

    void scanLoop() {
        while (m_running) {
            scan();
            Sleep(SCAN_INTERVAL);
        }
    }

    void scan() {
        HANDLE process = OpenProcess(PROCESS_VM_READ, FALSE, m_pid);
        if (!process) return;

        BYTE   buffer[SCAN_SIZE];
        SIZE_T bytesRead = 0;

        if (ReadProcessMemory(process, reinterpret_cast<LPCVOID>(m_base),
            buffer, sizeof(buffer), &bytesRead))
        {
            searchForPointers(buffer, bytesRead);
        }

        CloseHandle(process);
    }

    void searchForPointers(const BYTE* data, SIZE_T size) {
        const uintptr_t rangeEnd = m_base + RANGE_LIMIT;
        const SIZE_T    stride = sizeof(uintptr_t);

        for (SIZE_T i = 0; i + stride <= size; i += stride) {
            uintptr_t candidate = *reinterpret_cast<const uintptr_t*>(data + i);
            if (candidate > m_base && candidate < rangeEnd) {
                printf("Pointer found at offset 0x%zX -> 0x%zX\n", i, candidate);
                break;
            }
        }
    }
};