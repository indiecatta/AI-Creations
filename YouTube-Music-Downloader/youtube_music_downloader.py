import logging
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
import time
import requests
import re
import random
import psutil
import concurrent.futures
from tqdm import tqdm

# Logging setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)
file_handler = logging.FileHandler('logfile.log')
console_handler = logging.StreamHandler()

formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)
logger.addHandler(file_handler)
logger.addHandler(console_handler)

CPU_THRESHOLD = 50
RAM_THRESHOLD = 80

def resources_available():
    cpu_usage = psutil.cpu_percent(interval=1)
    ram_usage = psutil.virtual_memory().percent
    logging.info(f"CPU Usage: {cpu_usage}%, RAM Usage: {ram_usage}%")
    return cpu_usage < CPU_THRESHOLD and ram_usage < RAM_THRESHOLD

def sanitize_filename(string):
    invalid_chars = r'[<>:"/\\|?*]'
    safe_string = re.sub(invalid_chars, '_', string)
    return safe_string

def read_songs(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            songs = list(set(line.strip() for line in file if line.strip()))
        logging.info(f"Read {len(songs)} unique songs.")
        random.shuffle(songs)
        return songs
    except FileNotFoundError:
        logging.error(f"The file {file_path} was not found.")
        return []

def get_youtube_title(driver, youtube_link):
    try:
        logging.info(f"Opening YouTube link: {youtube_link}")
        driver.get(youtube_link)
        title_element = WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'yt-formatted-string[class="style-scope ytd-watch-metadata"]'))
        )
        logging.info("Video title found.")
        return title_element.text
    except Exception as e:
        logging.error(f"Error retrieving title: {e}")
        return None

def download_file(url, file_path):
    temp_file_path = os.path.join(download_dir, file_path + '.temp')
    logging.info(f"Starting download from: {url}")
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    block_size = 1024

    with open(temp_file_path, "wb") as file, tqdm(total=total_size, unit='iB', unit_scale=True, desc=temp_file_path) as progress_bar:
        for data in response.iter_content(block_size):
            progress_bar.update(len(data))
            file.write(data)

    logging.info(f"Download complete: {temp_file_path}")
    os.rename(temp_file_path, os.path.join(download_dir, file_path))
    logging.info(f"File renamed to: {file_path}")

def process_songs(songs):
    logging.info("Starting song downloads.")
    with concurrent.futures.ThreadPoolExecutor(max_workers=15) as executor:
        futures = []
        for song in songs:
            while not resources_available():
                logging.info("Resources at limit, waiting...")
                time.sleep(5)
            futures.append(executor.submit(search_youtube_and_download, song))
            time.sleep(5)  # Reduced waiting time
        concurrent.futures.wait(futures)

def search_youtube_and_download(song_title):
    try:
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("--disable-search-engine-choice-screen")
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--mute-audio")
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

        logging.info(f"Searching for video: {song_title}")
        search_url = f"https://www.youtube.com/results?search_query={'+'.join(song_title.split())}"
        driver.get(search_url)

        video_element = WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'a#video-title'))
        )
        video_link = f"{video_element.get_attribute('href')}"
        logging.info(f"Video found: {video_link}")

        video_title = get_youtube_title(driver, video_link)
        if video_title:
            safe_title = sanitize_filename(video_title)
            file_path = f"{safe_title}.m4a"
            if os.path.isfile(os.path.join(download_dir, file_path)):
                logging.info("Song already downloaded.")
            else:
                download_from_converter(driver, video_link, video_title)
        else:
            logging.warning("Video title not found, skipping.")

    except Exception as e:
        logging.error(f"Error searching for video: {e}")
    finally:
        driver.quit()

def download_from_converter(driver, youtube_link, video_title):
    try:
        logging.info(f"Opening converter for: {video_title}")
        driver.get("https://www.submagic.co/it/tools/youtube-to-mp3-converter")
        iframe = WebDriverWait(driver, 15).until(EC.presence_of_element_located((By.TAG_NAME, "iframe")))
        driver.switch_to.frame(iframe)
        input_box = WebDriverWait(driver, 15).until(EC.presence_of_element_located((By.XPATH, '//input[@placeholder="Enter YouTube URL"]')))
        input_box.send_keys(youtube_link)

        convert_button = WebDriverWait(driver, 15).until(EC.element_to_be_clickable((By.CSS_SELECTOR, 'button')))
        convert_button.click()

        time.sleep(5)
        buttons = WebDriverWait(driver, 15).until(EC.presence_of_all_elements_located((By.CSS_SELECTOR, 'button')))
        download_button = WebDriverWait(driver, 30).until(EC.element_to_be_clickable(buttons[1]))
        download_button.click()

        WebDriverWait(driver, 10).until(lambda d: len(d.window_handles) == 2)
        driver.switch_to.window(driver.window_handles[-1])
        m4a_url = driver.current_url
        driver.close()
        driver.switch_to.window(driver.window_handles[-1])

        safe_filename = sanitize_filename(video_title)
        m4a_file_path = os.path.join(download_dir, f"{safe_filename}.m4a")
        download_file(m4a_url, m4a_file_path)
    except Exception as e:
        logging.error(f"Error converting video {video_title}: {e}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.realpath(__file__))
    download_dir = os.path.join(script_dir, 'downloads')

    if not os.path.exists(download_dir):
        os.makedirs(download_dir)

    file_path = 'songs.txt'
    songs_list = read_songs(file_path)
    process_songs(songs_list)
