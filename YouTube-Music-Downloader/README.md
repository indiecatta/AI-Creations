# YouTube Music Downloader

This Python-based script automates downloading multiple songs from YouTube and converts them into **M4A** files. You can feed the script an entire list of song titles, and it will automatically find the videos on YouTube, download them, and convert them for you. The script also uses multithreading to handle multiple downloads simultaneously while ensuring that system resources (CPU and RAM) are not overwhelmed.

## Features

- **YouTube Search Automation**: Automatically searches YouTube for each song title in a list.
- **M4A File Downloads**: Converts YouTube videos to M4A format using an online converter.
- **Multithreaded Downloads**: Downloads multiple songs at once, making it efficient for large music libraries.
- **System Resource Monitoring**: Monitors CPU and RAM usage to avoid system overload.

## Requirements

- **Python 3.x**: You can download it [here](https://www.python.org/downloads/).
- **Google Chrome** and **Chromedriver** (handled automatically by the script).

## Setup Instructions

### 1. Install Python

If you don't already have Python installed, download it from [here](https://www.python.org/downloads/) and ensure that the option to add Python to your system path is checked during installation.

### 2. Install Required Libraries

Once Python is installed, open your terminal or command prompt, and run the following command to install the required Python libraries:

```
pip install selenium requests tqdm psutil webdriver-manager
```

This command installs:
- **Selenium** for browser automation,
- **Requests** for handling HTTP downloads,
- **tqdm** for progress bars,
- **psutil** for monitoring system resources,
- **webdriver-manager** to automatically manage the required Chromedriver version.

### 3. Create a List of Songs

Create a file named `songs.txt` in the same directory as the Python script. Add the song titles you want to download, one per line. The script will use this list to search for YouTube videos and download their audio as M4A files.

For example, `songs.txt` might look like this:

```
Song Title 1
Song Title 2
Song Title 3
```

### 4. Run the Script

Once you've set up the song list, navigate to the folder where the Python script is located using the terminal or command prompt. Then, run the following command:

```
python music_downloader.py
```

The script will:
1. Read the song titles from `songs.txt`.
2. Search YouTube for each song.
3. Download the video and convert it to an M4A file.
4. Save all downloaded files in a `downloads` folder inside the script directory.

## How It Works

- **Search YouTube**: For each song title, the script searches YouTube for the top result.
- **Download and Conversion**: It uses an online converter to transform the video into an M4A audio file.
- **Multithreading**: Multiple downloads happen in parallel to save time.
- **Resource Monitoring**: The script checks system CPU and RAM usage before launching new downloads to prevent overloading.

## Troubleshooting

- **Slow Downloads**: The script intentionally waits between downloads to ensure system resources are not overused. If you have a powerful system, you can adjust the delay by modifying the `time.sleep()` values in the code.
- **Chromedriver Issues**: If you're having problems with Chromedriver, ensure that Chrome is up to date. The script uses **webdriver-manager** to automatically manage the Chromedriver version.

## Disclaimer

This script is intended for downloading **royalty-free music** or music that you have the rights to download. Downloading copyrighted content without permission may violate YouTube's [Terms of Service](https://www.youtube.com/static?gl=US&template=terms) and local copyright laws.

Use this tool responsibly, and only for downloading legal content!

## Contributions

Feel free to submit pull requests or issues if you have any improvements or run into any problems.
