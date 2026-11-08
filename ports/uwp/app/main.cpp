#include <Windows.h>
#include <fileapifromapp.h>
#include <SDL.h>
#include <string>
#include <vector>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Storage.h>

#include "game_config.h"

extern "C" int SDL_main(int argc, char **argv);

namespace
{

// Must match t.identity in conf.lua: LÖVE's save directory on UWP is
// LocalState\<identity>, and the launcher scans its baseroms folder.
constexpr wchar_t kSaveIdentity[] = L"pokemon-love2d";

bool hasRomExtension(const std::wstring &name)
{
    size_t dot = name.find_last_of(L'.');
    if (dot == std::wstring::npos) {
        return false;
    }
    std::wstring ext = name.substr(dot + 1);
    for (auto &c : ext) {
        c = static_cast<wchar_t>(towlower(c));
    }
    return ext == L"gb" || ext == L"gbc" || ext == L"gba";
}

bool sameFile(const WIN32_FILE_ATTRIBUTE_DATA &a, const WIN32_FILE_ATTRIBUTE_DATA &b)
{
    return a.nFileSizeHigh == b.nFileSizeHigh && a.nFileSizeLow == b.nFileSizeLow
        && CompareFileTime(&a.ftLastWriteTime, &b.ftLastWriteTime) <= 0;
}

// Single-game packages read their ROM from a folder under
// D:\DevelopmentFiles, which Xbox Device Portal can upload to.  The launcher
// only reads LÖVE's save directory, so copy every .gb/.gbc/.gba there into
// LocalState\pokemon-love2d\baseroms; the launcher finds it by SHA-1 and,
// for a locked package, imports it without a button press.  Everything here
// is best effort: a missing folder or a denied read leaves the file picker.
void copyDevelopmentFiles()
{
    const std::wstring source = GEN1RECOMP_DEV_FOLDER;
    if (source.empty()) {
        return;
    }
    // Create the folder so it is visible in Device Portal for the first upload.
    CreateDirectoryFromAppW(source.c_str(), nullptr);

    std::wstring dest = winrt::Windows::Storage::ApplicationData::Current()
        .LocalFolder().Path().c_str();
    dest += L"\\";
    dest += kSaveIdentity;
    CreateDirectoryFromAppW(dest.c_str(), nullptr);
    dest += L"\\baseroms";
    CreateDirectoryFromAppW(dest.c_str(), nullptr);

    std::vector<std::wstring> names;
    WIN32_FIND_DATAW found{};
    HANDLE find = FindFirstFileExFromAppW((source + L"\\*").c_str(), FindExInfoBasic,
        &found, FindExSearchNameMatch, nullptr, 0);
    if (find == INVALID_HANDLE_VALUE) {
        return;
    }
    do {
        if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0
                && found.cFileName[0] != L'.' && hasRomExtension(found.cFileName)) {
            names.emplace_back(found.cFileName);
        }
    } while (FindNextFileW(find, &found));
    FindClose(find);

    for (const auto &name : names) {
        std::wstring from = source + L"\\" + name;
        std::wstring to = dest + L"\\" + name;
        WIN32_FILE_ATTRIBUTE_DATA src{};
        WIN32_FILE_ATTRIBUTE_DATA dst{};
        if (!GetFileAttributesExFromAppW(from.c_str(), GetFileExInfoStandard, &src)) {
            continue;
        }
        if (GetFileAttributesExFromAppW(to.c_str(), GetFileExInfoStandard, &dst)
                && sameFile(src, dst)) {
            continue;
        }
        CopyFileFromAppW(from.c_str(), to.c_str(), FALSE);
    }
}

int runLove(int, char **)
{
    copyDevelopmentFiles();

    std::wstring packagePath = winrt::Windows::ApplicationModel::Package::Current()
        .InstalledLocation().Path().c_str();
    std::string gamePath = winrt::to_string(packagePath + L"\\gen1recomp.love");

    char executable[] = "Gen1RecompUWP";
    char fused[] = "--fused";
    std::string gameArg = std::string("--game=") + GEN1RECOMP_GAME_ID;
    std::string lockArg = std::string("--lock-game=") + GEN1RECOMP_GAME_ID;
    std::vector<char *> loveArgv = {executable, gamePath.data(), fused};
    if (GEN1RECOMP_GAME_ID[0] != '\0') {
        loveArgv.push_back(gameArg.data());
        loveArgv.push_back(lockArg.data());
    }
    int argc = static_cast<int>(loveArgv.size());
    loveArgv.push_back(nullptr);
    return SDL_main(argc, loveArgv.data());
}

} // namespace

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
    SDL_SetHint(SDL_HINT_WINRT_HANDLE_BACK_BUTTON, "1");
    return SDL_WinRTRunApp(runLove, nullptr);
}
