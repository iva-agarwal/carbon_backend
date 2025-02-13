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
nonrenw_energytocarbon = 441  # g/kWh
renw_energytocarbon = 50  # g/kWh
datatoenergy = 0.81  # kWh/GB

chrome_path = os.getenv("CHROME_BIN", "/tmp/chrome/opt/google/chrome/google-chrome")

options = webdriver.ChromeOptions()
options.binary_location = chrome_path  # Set the correct path

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
def fetch_resource_size(resource_url):
    response = requests.get(resource_url)
    if response.status_code == 200:
        content_length = response.headers.get('Content-Length')
        return int(content_length) if content_length else len(response.content)
    return 0

def getsource(tag):
    for attr in ['src', 'data-src', 'data-gt-lazy-src', 'href', 'xlink:href', 'poster', 'srcset', 'data-url', 'data-example', 'action']:
        src = tag.get(attr)
        if src and not src.startswith("data:image/"):
            return src
    return None

def calculate_data_transfer(url):
    css_size_bytes = font_size_bytes = js_size_bytes = media_size_bytes = 0
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    driver.get(url)
    html_content = driver.page_source
    driver.quit()
    soup = BeautifulSoup(html_content, 'html.parser')

    html_size_bytes = len(html_content)

    for link_tag in soup.find_all('link', rel='stylesheet'):
        src = getsource(link_tag)
        if src:
            css_url = urljoin(url, src)
            css_size_bytes += fetch_resource_size(css_url)

    for script_tag in soup.find_all('script'):
        src = getsource(script_tag)
        if src:
            js_size_bytes += fetch_resource_size(urljoin(url, src))

    for media_tag in soup.find_all(['video', 'audio', 'img']):
        src = getsource(media_tag)
        if src:
            media_size_bytes += fetch_resource_size(urljoin(url, src))

    return (
        css_size_bytes / (1024 ** 3),  # Convert bytes to GB
        font_size_bytes / (1024 ** 3),
        js_size_bytes / (1024 ** 3),
        media_size_bytes / (1024 ** 3),
        html_size_bytes / (1024 ** 3)
    )

def check_green_website(url):
    parsed_url = urlparse(url).netloc
    api_url = f"https://api.thegreenwebfoundation.org/api/v3/greencheck/{parsed_url}"
    response = requests.get(api_url)
    return response.json().get("green", False) if response.status_code == 200 else False

def calculate_carbon(data, green):
    energy_factor = renw_energytocarbon if green else nonrenw_energytocarbon
    return energy_factor * datatoenergy * data

@app.get("/calculate_footprint")
def calculate_footprint(web_url: str = Query(..., title="Website URL", description="URL of the website to analyze")):
    try:
        data_gb = calculate_data_transfer(web_url)
        total_data = sum(data_gb)
        green = check_green_website(web_url)
        carbon = calculate_carbon(total_data, green)
        return {
            "css_data_gb": data_gb[0],
            "font_data_gb": data_gb[1],
            "js_data_gb": data_gb[2],
            "media_data_gb": data_gb[3],
            "html_data_gb": data_gb[4],
            "total_data_gb": total_data,
            "Carbon_footprint": carbon,
            "Green_hosting": green,
        }
    except Exception as e:
        return {"error": str(e)}
