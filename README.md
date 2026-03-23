# Local Transcription Pipeline

A local pipeline for processing long audio or video recordings into text.

## What it does

This project takes a recording (audio or video), prepares it for transcription, splits it into manageable chunks, and transcribes it locally using faster-whisper.

Everything runs on your machine - no uploads, no cloud services.

## How it works

input file -> source audio -> chunks -> transcription -> text files

Chunking is handled automatically and is not something the user needs to manage.

## Usage

Run:
scripts/run_recording_picker.bat

Select a file, and the pipeline will:
- prepare the audio
- split it into chunks
- transcribe it
- save the results in the output folder

If files already exist, you can choose whether to reuse or overwrite them.

## Output

Each run creates a folder in output/ with:
- processed audio
- chunk files (internal)
- per-chunk transcripts
- a combined transcript (full_transcript.txt)

## Notes

- runs locally using CPU
- slower than cloud tools, but private and controllable
- designed for long recordings

## Requirements

- Python 3.10+
- ffmpeg (included in tools/)
- Python packages:
  - faster-whisper
  - tqdm
  - pydub
