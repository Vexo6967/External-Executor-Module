#pragma once

#include "Bridge.hpp"

#include "Utils/tphandler.h"

#include <iostream>

#include <Windows.h>

#include <string>

#include <vector>

#include <thread>

#pragma comment(lib, "urlmon.lib")

#include <urlmon.h>



#include "Utils/Process.hpp"

#include "Utils/Instance.hpp"

#include "Utils/Bytecode.hpp"

bool Injected = false;

std::string GetLuaCode(DWORD pid, int idx) {

    HMODULE hModule = NULL;

    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,

        (LPCWSTR)&GetLuaCode, &hModule);



    HRSRC resourceHandle = FindResourceW(hModule, MAKEINTRESOURCEW(idx), RT_RCDATA);

    if (resourceHandle == NULL)

    {

        return "";

    }



    HGLOBAL loadedResource = LoadResource(hModule, resourceHandle);

    if (loadedResource == NULL)

    {

        return "";

    }



    DWORD size = SizeofResource(hModule, resourceHandle);

    void* data = LockResource(loadedResource);



    std::string code = std::string(static_cast<char*>(data), size);

    size_t pos = code.find("%-PROCESS-ID-%");

    if (pos != std::string::npos) {

        code.replace(pos, 14, std::to_string(pid));

    }



    return code;

}

void decompiler()

{

    std::filesystem::path folder = std::filesystem::current_path() / "bin";

    std::filesystem::create_directories(folder);

    std::filesystem::path exePath = folder / "server.exe";



    if (!std::filesystem::exists(exePath))

    {

        const char* url = "https://raw.githubusercontent.com/HyperCraxy/ArlxAPI/main/server.exe";

        HRESULT hr = URLDownloadToFileA(nullptr, url, exePath.string().c_str(), 0, nullptr);

        if (FAILED(hr)) return;

    }



    STARTUPINFOA si{};

    PROCESS_INFORMATION pi{};

    si.cb = sizeof(si);

    si.dwFlags = STARTF_USESHOWWINDOW;

    si.wShowWindow = SW_HIDE;

    if (CreateProcessA(nullptr, const_cast<char*>(exePath.string().c_str()), nullptr, nullptr, FALSE, 0, nullptr, nullptr, &si, &pi))

    {

        CloseHandle(pi.hThread);

        CloseHandle(pi.hProcess);

    }



    std::thread([] {

        HANDLE self = OpenProcess(SYNCHRONIZE, FALSE, GetCurrentProcessId());

        if (self) {

            WaitForSingleObject(self, INFINITE);

            CloseHandle(self);

        }

        }).detach();

}

int main()

{

    printf("[*] starting bridge thread\n");

    std::thread(StartBridge).detach();

    printf("[*] starting decompiler server");

    std::thread(decompiler).detach();

    printf("[*] getting process list\n");

    std::vector<DWORD> pids = Process::GetProcessID();

    printf("[+] found %zu processes\n", pids.size());



    for (DWORD pid : pids) {

        printf("[*] checking process %lu\n", pid);



        uintptr_t base = Process::GetModuleBase(pid);

        if (!base) {

            printf("[-] failed to get module base for pid %lu\n", pid);

            continue;

        }

        printf("[+] got module base: 0x%p\n", (void*)base);

        TPHandler* tpHandler = new TPHandler(pid, base);
        tpHandler->start();

        Instance Datamodel = FetchDatamodel(base, pid);

        if (!Datamodel.GetAddress()) {

            printf("[-] failed to fetch datamodel for pid %lu\n", pid);

            continue;

        }

        printf("[+] datamodel name: %s\n", Datamodel.Name().c_str());



        size_t inits;

        std::string initLua = GetLuaCode(pid, 1);

        std::vector<char> initb = Bytecode::Sign(Bytecode::Compile(initLua), inits);

        printf("[+] compiled init script, size: %zu\n", inits);



        if (Datamodel.Name() == "Ugc") {

            printf("[*] handling ugc datamodel\n");



            printf("[*] finding coregui\n");

            Instance CoreGui = Datamodel.FindFirstChild("CoreGui");

            if (!CoreGui.GetAddress()) {

                printf("[-] coregui not found\n");

                continue;

            }



            printf("[*] finding robloxgui\n");

            Instance RobloxGui = CoreGui.FindFirstChild("RobloxGui");

            if (!RobloxGui.GetAddress()) {

                printf("[-] robloxgui not found\n");

                continue;

            }



            printf("[*] finding modules\n");

            Instance Modules = RobloxGui.FindFirstChild("Modules");

            if (!Modules.GetAddress()) {

                printf("[-] modules not found\n");

                continue;

            }



            printf("[*] finding playerlist\n");

            Instance PlayerList = Modules.FindFirstChild("PlayerList");

            if (!PlayerList.GetAddress()) {

                printf("[-] playerlist not found\n");

                continue;

            }



            printf("[*] finding playerlistmanager\n");

            Instance PlmModule = PlayerList.FindFirstChild("PlayerListManager");

            if (!PlmModule.GetAddress()) {

                printf("[-] playerlistmanager not found\n");

                continue;

            }



            printf("[*] finding collision matchers\n");

            Instance CorePackages = Datamodel.FindFirstChild("CorePackages");

            Instance Packages = CorePackages.FindFirstChild("Packages");

            Instance Index = Packages.FindFirstChild("_Index");

            Instance Cm2D1 = Index.FindFirstChild("CollisionMatchers2D");

            Instance Cm2D2 = Cm2D1.FindFirstChild("CollisionMatchers2D");

            Instance Jest = Cm2D2.FindFirstChild("Jest");



            if (!Jest.GetAddress()) {

                printf("[-] jest module not found\n");

                continue;

            }



            printf("[*] enabling load module\n");

            WriteMemory<BYTE>(base + offsets::EnableLoadModule, 1, pid);



            printf("[*] hijacking playerlistmanager\n");

            WriteMemory<uintptr_t>(PlmModule.GetAddress() + 0x8, Jest.GetAddress(), pid);



            printf("[*] setting jest bytecode\n");

            auto revert1 = Jest.SetScriptBytecode(initb, inits);



            printf("[*] bringing window to foreground\n");

            HWND hwnd = Process::GetWindowsProcess(pid);

            HWND old = GetForegroundWindow();

            while (GetForegroundWindow() != hwnd) {

                SetForegroundWindow(hwnd);

                Sleep(1);

            }



            printf("[*] sending escape key\n");

            keybd_event(VK_ESCAPE, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE, 0);

            keybd_event(VK_ESCAPE, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP, 0);



            printf("[*] waiting for Only-Skids gui\n");

            CoreGui.WaitForChild("Only-Skids");

            printf("[+] Only-Skids gui loaded\n");

            // ✅ OPRAVA: Injected = true AZ TU, po realnom potvrdeni
            Injected = true;

            Sleep(250);
            keybd_event(VK_ESCAPE, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE, 0);
            keybd_event(VK_ESCAPE, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP, 0);


            printf("[*] restoring foreground window\n");

            SetForegroundWindow(old);



            printf("[*] restoring playerlistmanager\n");

            WriteMemory<uintptr_t>(PlmModule.GetAddress() + 0x8, PlmModule.GetAddress(), pid);



            printf("[*] reverting bytecode\n");

            revert1();

            printf("[+] ugc injection complete\n");

            // tp handler
            std::thread([pid, base, initb, inits]() {
                uintptr_t lastDM = 0;

                while (true) {
                    Instance currentDM = FetchDatamodel(base, pid);

                    if (!currentDM.GetAddress()) {
                        Sleep(1000);
                        continue;
                    }

                    if (currentDM.GetAddress() != lastDM && lastDM != 0) {

                        Instance CoreGui = currentDM.FindFirstChild("CoreGui");
                        if (!CoreGui.GetAddress()) continue;

                        Instance RobloxGui = CoreGui.FindFirstChild("RobloxGui");
                        if (!RobloxGui.GetAddress()) continue;

                        Instance Modules = RobloxGui.FindFirstChild("Modules");
                        if (!Modules.GetAddress()) continue;

                        Instance PlayerList = Modules.FindFirstChild("PlayerList");
                        if (!PlayerList.GetAddress()) continue;

                        Instance PlmModule = PlayerList.FindFirstChild("PlayerListManager");
                        if (!PlmModule.GetAddress()) continue;

                        Instance CorePackages = currentDM.FindFirstChild("CorePackages");
                        Instance Packages = CorePackages.FindFirstChild("Packages");
                        Instance Index = Packages.FindFirstChild("_Index");
                        Instance Cm2D1 = Index.FindFirstChild("CollisionMatchers2D");
                        Instance Cm2D2 = Cm2D1.FindFirstChild("CollisionMatchers2D");
                        Instance Jest = Cm2D2.FindFirstChild("Jest");

                        if (!Jest.GetAddress()) continue;

                        WriteMemory<BYTE>(base + offsets::EnableLoadModule, 1, pid);
                        WriteMemory<uintptr_t>(PlmModule.GetAddress() + 0x8, Jest.GetAddress(), pid);
                        auto revert = Jest.SetScriptBytecode(initb, inits);

                    }

                    lastDM = currentDM.GetAddress();
                    Sleep(2000);
                }
                }).detach();

        }

        else {

            printf("[*] setting up watcher for ugc datamodel\n");

            std::thread([=]() {

                Instance Datamodel = Instance(0, pid);

                int attempts = 0;

                while (true) {

                    Datamodel = FetchDatamodel(base, pid);

                    if (Datamodel.Name() == "Ugc") {

                        printf("[+] ugc datamodel found after %d attempts\n", attempts);

                        break;

                    }

                    attempts++;

                    if (attempts % 10 == 0) {

                        printf("[*] still waiting for ugc datamodel... (%d attempts)\n", attempts);

                    }

                    Sleep(250);

                }



                printf("[*] finding coregui\n");

                Instance CoreGui = Datamodel.FindFirstChild("CoreGui");

                if (!CoreGui.GetAddress()) {

                    printf("[-] coregui not found\n");

                    return;

                }



                printf("[*] finding robloxgui\n");

                Instance RobloxGui = CoreGui.FindFirstChild("RobloxGui");

                if (!RobloxGui.GetAddress()) {

                    printf("[-] robloxgui not found\n");

                    return;

                }



                printf("[*] finding modules\n");

                Instance Modules = RobloxGui.FindFirstChild("Modules");

                if (!Modules.GetAddress()) {

                    printf("[-] modules not found\n");

                    return;

                }



                printf("[*] finding avatareditorprompts\n");

                Instance InitModule = Modules.FindFirstChild("AvatarEditorPrompts");

                if (!InitModule.GetAddress()) {

                    printf("[-] avatareditorprompts not found\n");

                    return;

                }



                printf("[*] enabling load module\n");

                WriteMemory<BYTE>(base + offsets::EnableLoadModule, 1, pid);



                printf("[*] setting init module bytecode\n");

                auto revert1 = InitModule.SetScriptBytecode(initb, inits);



                printf("[*] waiting for Only-Skids gui\n");

                CoreGui.WaitForChild("Only-Skids");

                printf("[+] Only-Skids gui loaded\n");

                // ✅ OPRAVA: Injected = true AZ TU, po realnom potvrdeni
                Injected = true;

                printf("[*] reverting bytecode\n");

                revert1();

                printf("[+] non-ugc injection complete\n");

                // non ugc 
                std::thread([pid, base, initb, inits]() {
                    uintptr_t lastDM = 0;

                    while (true) {
                        Instance currentDM = FetchDatamodel(base, pid);

                        if (!currentDM.GetAddress()) {
                            Sleep(1000);
                            continue;
                        }

                        if (currentDM.GetAddress() != lastDM && lastDM != 0) {

                            Instance CoreGui = currentDM.FindFirstChild("CoreGui");
                            if (!CoreGui.GetAddress()) continue;

                            Instance RobloxGui = CoreGui.FindFirstChild("RobloxGui");
                            if (!RobloxGui.GetAddress()) continue;

                            Instance Modules = RobloxGui.FindFirstChild("Modules");
                            if (!Modules.GetAddress()) continue;

                            Instance InitModule = Modules.FindFirstChild("AvatarEditorPrompts");
                            if (!InitModule.GetAddress()) continue;

                            WriteMemory<BYTE>(base + offsets::EnableLoadModule, 1, pid);
                            auto revert = InitModule.SetScriptBytecode(initb, inits);
                        }

                        lastDM = currentDM.GetAddress();
                        Sleep(2000);
                    }
                    }).detach();

                }).detach();
        }

    }



    printf("[*] main loop finished\n");

    return 0;

}



std::string Convert(const wchar_t* wideStr) {

    if (!wideStr) return "";

    int size_needed = WideCharToMultiByte(

        CP_UTF8, 0, wideStr, -1, nullptr, 0, nullptr, nullptr

    );

    if (size_needed == 0) return "";

    std::string result(size_needed, 0);

    WideCharToMultiByte(

        CP_UTF8, 0, wideStr, -1, &result[0], size_needed, nullptr, nullptr

    );

    if (!result.empty() && result.back() == '\0') {

        result.pop_back();

    }

    return result;

}

extern "C" __declspec(dllexport) bool IsAttached()
{
    return Injected;
}

extern "C" __declspec(dllexport) void Only_Skids(const wchar_t* input) {
    if (!Injected) {
        std::thread([=]() {
            main();
        }).detach();
    }

    std::string source = Convert(input);
    if (source.length() >= 1) {
        Execute(source);
    }
}