import os
from fastapi import FastAPI, Query
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import requests
import re
from webdriver_manager.chrome import ChromeDriverManager

# Initialize FastAPI app
app = FastAPI()

# Constants
NON_RENEWABLE_CARBON = 441  # g/kWh
RENEWABLE_CARBON = 50  # g/kWh
DATA_TO_ENERGY = 0.81  # kWh/GB

# Configure Chrome
chrome_path = os.getenv("CHROME_BIN", "/usr/bin/google-chrome-stable")

options = webdriver.ChromeOptions()
options.binary_location = chrome_path
options.add_argument("--headless")  # Run in headless mode
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

def fetch_resource_size(resource_url):
    try:
        response = requests.get(resource_url, timeout=10)
        if response.status_code == 200:
            content_length = response.headers.get('Content-Length')
            return int(content_length) if content_length else len(response.content)
    except requests.RequestException:
        pass
    return 0

def get_source(tag):
    """ Extracts the URL from various attributes of an HTML tag. """
    for attr in ['src', 'data-src', 'data-gt-lazy-src', 'href', 'xlink:href', 'poster', 'srcset', 'data-url']:
        src = tag.get(attr)
        if src and not src.startswith("data:image/"):  # Ignore base64 images
            return src
    return None

def calculate_data_transfer(url):
    """ Calculates the data transfer size of different website resources. """
    css_size_bytes = js_size_bytes = media_size_bytes = 0

    with webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options) as driver:
        driver.get(url)
        html_content = driver.page_source

    soup = BeautifulSoup(html_content, 'html.parser')
    html_size_bytes = len(html_content)

    for tag in soup.find_all(['link', 'script', 'video', 'audio', 'img']):
        src = get_source(tag)
        if src:
            resource_url = urljoin(url, src)
            size_bytes = fetch_resource_size(resource_url)

            if tag.name == 'link' and tag.get('rel') == ['stylesheet']:
                css_size_bytes += size_bytes
            elif tag.name == 'script':
                js_size_bytes += size_bytes
            elif tag.name in ['video', 'audio', 'img']:
                media_size_bytes += size_bytes

    return (
        css_size_bytes / (1024 ** 3),  # Convert bytes to GB
        js_size_bytes / (1024 ** 3),
        media_size_bytes / (1024 ** 3),
        html_size_bytes / (1024 ** 3)
    )

def check_green_website(url):
    """ Checks if the website is hosted on green energy. """
    parsed_url = urlparse(url).netloc
    api_url = f"https://api.thegreenwebfoundation.org/api/v3/greencheck/{parsed_url}"
    try:
        response = requests.get(api_url, timeout=10)
        return response.json().get("green", False) if response.status_code == 200 else False
    except requests.RequestException:
        return False

def calculate_carbon(data, green):
    """ Calculates the carbon footprint based on the data transfer. """
    energy_factor = RENEWABLE_CARBON if green else NON_RENEWABLE_CARBON
    return energy_factor * DATA_TO_ENERGY * data

@app.get("/calculate_footprint")
def calculate_footprint(web_url: str = Query(..., title="Website URL", description="URL of the website to analyze")):
    try:
        css, js, media, html = calculate_data_transfer(web_url)
        total_data = css + js + media + html
        green = check_green_website(web_url)
        carbon = calculate_carbon(total_data, green)

        return {
            "css_data_gb": css,
            "js_data_gb": js,
            "media_data_gb": media,
            "html_data_gb": html,
            "total_data_gb": total_data,
            "carbon_footprint_gCO2": carbon,
            "green_hosting": green,
        }
    except Exception as e:
        return {"error": str(e)}
