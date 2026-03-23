import os
import sys
import time
from pathlib import Path

from faster_whisper import WhisperModel
from tqdm import tqdm
from pydub import AudioSegment


def format_seconds(seconds: float) -> str:
    total_seconds = int(seconds)
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    secs = total_seconds % 60
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


def get_audio_duration_seconds(audio_path: Path) -> float:
    audio = AudioSegment.from_file(audio_path)
    return len(audio) / 1000.0


def main():
    if len(sys.argv) < 2:
        print("usage: python transcribe_chunks.py <output_folder> [overwrite_transcripts]")
        sys.exit(1)

    script_dir = Path(__file__).resolve().parent
    project_dir = script_dir.parent
    ffmpeg_bin_dir = project_dir / "tools" / "ffmpeg-8.1-essentials_build" / "bin"

    ffmpeg_exe = ffmpeg_bin_dir / "ffmpeg.exe"
    ffprobe_exe = ffmpeg_bin_dir / "ffprobe.exe"

    if not ffmpeg_exe.exists():
        print(f"ffmpeg not found: {ffmpeg_exe}")
        sys.exit(1)

    if not ffprobe_exe.exists():
        print(f"ffprobe not found: {ffprobe_exe}")
        sys.exit(1)

    os.environ["PATH"] = str(ffmpeg_bin_dir) + os.pathsep + os.environ.get("PATH", "")
    AudioSegment.converter = str(ffmpeg_exe)
    AudioSegment.ffprobe = str(ffprobe_exe)

    output_dir = Path(sys.argv[1]).resolve()
    overwrite_transcripts = "n"

    if len(sys.argv) >= 3:
        overwrite_transcripts = sys.argv[2].strip().lower()

    if not output_dir.exists():
        print("output folder not found")
        sys.exit(1)

    chunk_files = sorted(output_dir.glob("chunk_*.mp3"))

    if not chunk_files:
        print("no chunks found")
        sys.exit(1)

    transcripts_dir = output_dir / "transcripts"
    transcripts_dir.mkdir(exist_ok=True)

    print("loading faster-whisper model...")
    model = WhisperModel("base", device="cpu", compute_type="int8")

    full_text = []
    total_chunks = len(chunk_files)
    total_start_time = time.perf_counter()

    for chunk_index, chunk_file in enumerate(chunk_files, start=1):
        transcript_path = transcripts_dir / f"{chunk_file.stem}.txt"

        if transcript_path.exists() and overwrite_transcripts != "y":
            print(f"skipping {chunk_file.name} because transcript already exists")
            existing_text = transcript_path.read_text(encoding="utf-8").strip()
            full_text.append(f"## {chunk_file.stem}\n\n{existing_text}\n")
            continue

        chunk_duration = get_audio_duration_seconds(chunk_file)
        chunk_start_time = time.perf_counter()

        print("")
        print(
            f"chunk {chunk_index}/{total_chunks}: {chunk_file.name} "
            f"({format_seconds(chunk_duration)})"
        )

        segments, info = model.transcribe(
            str(chunk_file),
            language="he"
        )

        chunk_text_parts = []
        last_progress_seconds = 0.0

        with tqdm(
            total=max(1.0, chunk_duration),
            desc=f"{chunk_file.stem}",
            unit="sec",
            leave=True,
            dynamic_ncols=True
        ) as pbar:
            for seg in segments:
                chunk_text_parts.append(seg.text.strip())

                segment_end = min(float(seg.end), chunk_duration)
                increment = max(0.0, segment_end - last_progress_seconds)

                if increment > 0:
                    pbar.update(increment)
                    last_progress_seconds = segment_end

            if last_progress_seconds < chunk_duration:
                pbar.update(chunk_duration - last_progress_seconds)

        chunk_text = " ".join(part for part in chunk_text_parts if part).strip()
        transcript_path.write_text(chunk_text, encoding="utf-8")

        full_text.append(f"## {chunk_file.stem}\n\n{chunk_text}\n")

        chunk_elapsed = time.perf_counter() - chunk_start_time
        realtime_factor = chunk_duration / chunk_elapsed if chunk_elapsed > 0 else 0.0

        print(
            f"finished {chunk_file.name} in {format_seconds(chunk_elapsed)} "
            f"(audio length: {format_seconds(chunk_duration)}, "
            f"speed: {realtime_factor:.2f}x realtime)"
        )

    full_transcript_path = output_dir / "full_transcript.txt"
    full_transcript_path.write_text("\n".join(full_text), encoding="utf-8")

    total_elapsed = time.perf_counter() - total_start_time

    print("")
    print("done")
    print(f"chunk transcripts: {transcripts_dir}")
    print(f"full transcript: {full_transcript_path}")
    print(f"total elapsed: {format_seconds(total_elapsed)}")


if __name__ == "__main__":
    main()