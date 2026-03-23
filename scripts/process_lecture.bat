@echo off
setlocal

set "FFMPEG=%~dp0..\tools\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe"

if "%~1"=="" (
    echo drag and drop an mp4 file onto this script
    pause
    exit /b 1
)

set "INPUT=%~1"
set "BASENAME=%~n1"
set "OUTDIR=%~dp0..\output\%BASENAME%"
set "AUDIO=%OUTDIR%\lecture_audio.mp3"
set "CHUNKPATTERN=%OUTDIR%\chunk_%%03d.mp3"
set "TRANSCRIBE_SCRIPT=%~dp0transcribe_chunks.py"

if not exist "%FFMPEG%" (
    echo ffmpeg.exe not found here:
    echo %FFMPEG%
    pause
    exit /b 1
)

if not exist "%TRANSCRIBE_SCRIPT%" (
    echo transcription script not found here:
    echo %TRANSCRIBE_SCRIPT%
    pause
    exit /b 1
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

set "OVERWRITE_AUDIO=n"
set "OVERWRITE_CHUNKS=n"
set "OVERWRITE_TRANSCRIPTS=n"

echo.
echo output folder:
echo %OUTDIR%
echo.

if exist "%AUDIO%" (
    set /p OVERWRITE_AUDIO=audio already exists. overwrite? ^(y/n^): 
)

if exist "%OUTDIR%\chunk_000.mp3" (
    set /p OVERWRITE_CHUNKS=chunks already exist. overwrite? ^(y/n^): 
)

if exist "%OUTDIR%\transcripts" (
    set /p OVERWRITE_TRANSCRIPTS=transcripts may already exist. overwrite? ^(y/n^): 
)

echo.
if /i "%OVERWRITE_AUDIO%"=="y" (
    echo step 1: extracting audio...
    "%FFMPEG%" -y -i "%INPUT%" -vn -ac 1 -ar 16000 -b:a 32k "%AUDIO%"

    if errorlevel 1 (
        echo audio extraction failed
        pause
        exit /b 1
    )
) else (
    if exist "%AUDIO%" (
        echo step 1: reusing existing audio
    ) else (
        echo step 1: extracting audio...
        "%FFMPEG%" -y -i "%INPUT%" -vn -ac 1 -ar 16000 -b:a 32k "%AUDIO%"

        if errorlevel 1 (
            echo audio extraction failed
            pause
            exit /b 1
        )
    )
)

echo.
if /i "%OVERWRITE_CHUNKS%"=="y" (
    echo deleting old chunks...
    del /q "%OUTDIR%\chunk_*.mp3" >nul 2>&1

    echo step 2: splitting into 20-minute chunks...
    "%FFMPEG%" -y -i "%AUDIO%" -f segment -segment_time 1200 -c copy "%CHUNKPATTERN%"

    if errorlevel 1 (
        echo chunking failed
        pause
        exit /b 1
    )
) else (
    if exist "%OUTDIR%\chunk_000.mp3" (
        echo step 2: reusing existing chunks
    ) else (
        echo step 2: splitting into 20-minute chunks...
        "%FFMPEG%" -y -i "%AUDIO%" -f segment -segment_time 1200 -c copy "%CHUNKPATTERN%"

        if errorlevel 1 (
            echo chunking failed
            pause
            exit /b 1
        )
    )
)

echo.
echo step 3: transcribing chunks...
python "%TRANSCRIBE_SCRIPT%" "%OUTDIR%" "%OVERWRITE_TRANSCRIPTS%"

if errorlevel 1 (
    echo transcription failed
    pause
    exit /b 1
)

echo.
echo done
echo output folder:
echo %OUTDIR%
pause