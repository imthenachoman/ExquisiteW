; https://www.autohotkey.com/boards/viewtopic.php?p=463753#p463753
IsElevated(pid) {
    local result := false, proc
    local hToken := 0
    static TOKEN_QUERY := 0x0008
    static PROCESS_QUERY_INFORMATION := 0x0400
    try {
        if !proc := OpenProcess(PROCESS_QUERY_INFORMATION, false, pid) {
            static ERROR_ACCESS_DENIED := 0x5
            if !a_isadmin && a_lasterror == ERROR_ACCESS_DENIED
                return true ; probably :=)
            else throw OSError(, , 'OpenProcess')
        }
        if OpenProcessToken(proc, TOKEN_QUERY, &hToken) {

            static sizeof_elevation := 4
            static TokenElevation := 20
            local cbSize := 4
            local Elevation := 0

            if GetTokenInformation(hToken, TokenElevation, &Elevation, sizeof_elevation, &cbSize)
                result := Elevation
            else
                throw OSError(, , 'GetTokenInformation')

        }
        else
            throw OSError(, , 'OpenProcessToken')
    } finally {
        if hToken
            CloseHandle hToken
        if proc
            CloseHandle proc
    }
    return result

    ; Windows lib:
    /*
    HANDLE OpenProcess(
    [in] DWORD dwDesiredAccess,
    [in] BOOL  bInheritHandle,
    [in] DWORD dwProcessId
    );
    */
    OpenProcess(dwDesiredAccess, bInheritHandle, dwProcessId)
        => dllcall('Kernel32.dll\OpenProcess', 'uint', dwDesiredAccess, 'int', bInheritHandle, 'uint', dwProcessId, 'ptr')

    /*
       BOOL OpenProcessToken(
    [in]  HANDLE  ProcessHandle,
    [in]  DWORD   DesiredAccess,
    [out] PHANDLE TokenHandle
    );
    */

    OpenProcessToken(ProcessHandle, DesiredAccess, &TokenHandle)
        => dllcall('Advapi32.dll\OpenProcessToken', 'ptr', ProcessHandle, 'uint', DesiredAccess, 'ptr*', &TokenHandle, 'int')
    /*
    BOOL GetTokenInformation(
    [in]            HANDLE                  TokenHandle,
    [in]            TOKEN_INFORMATION_CLASS TokenInformationClass,
    [out, optional] LPVOID                  TokenInformation,
    [in]            DWORD                   TokenInformationLength,
    [out]           PDWORD                  ReturnLength
    	);
    */
    GetTokenInformation(
        TokenHandle,
        TokenInformationClass,
        &TokenInformation,
        TokenInformationLength,
        &ReturnLength
    )
        => dllcall('Advapi32.dll\GetTokenInformation',
            'ptr', TokenHandle,
            'ptr', TokenInformationClass,
            'uint*', &TokenInformation,
            'uint', TokenInformationLength,
            'uint*', &ReturnLength
        )
    /*
    BOOL CloseHandle(
    [in] HANDLE hObject
    );
    */
    CloseHandle(hObject)
        => dllcall('Kernel32.dll\CloseHandle', 'ptr', hObject, 'int')
    ; from: https://stackoverflow.com/questions/8046097/how-to-check-if-a-process-has-the-administrative-rights
}