from fastapi import FastAPI
from requests_html import HTMLSession
from urllib.parse import urljoin
import re

app = FastAPI()

# Constants
renw_energytocarbon = 50  # g/kWh
datatoenergy = 0.81  # kWh/GB

def fetch_resource_size(resource_url):
    """Fetches the size of a given resource (CSS, JS, media, etc.)."""
    session = HTMLSession()
    try:
        response = session.get(resource_url, timeout=10)
        if response.status_code == 200:
            return len(response.content)
    except Exception as e:
        print(f"Error fetching {resource_url}: {e}")
        return 0
    return 0

def calculate_data_transfer(url):
    """Calculates data transfer size for different resources (CSS, JS, media)."""
    css_size_bytes = 0
    js_size_bytes = 0
    media_size_bytes = 0

    session = HTMLSession()
    
    try:
        response = session.get(url, timeout=10)
        response.html.render(timeout=30)  # Render JavaScript

        html_content = response.content
        total_size_bytes = len(html_content)

        # Extract all linked resources
        for link_tag in response.html.find("link[rel='stylesheet']"):
            href = link_tag.attrs.get('href')
            if href:
                css_url = urljoin(url, href)
                css_size_bytes += fetch_resource_size(css_url)

        for script_tag in response.html.find("script"):
            src = script_tag.attrs.get('src')
            if src:
                js_url = urljoin(url, src)
                js_size_bytes += fetch_resource_size(js_url)

        for media_tag in response.html.find("video, audio"):
            src = media_tag.attrs.get('src')
            if src:
                media_url = urljoin(url, src)
                media_size_bytes += fetch_resource_size(media_url)

        # Convert bytes to GB
        css_transfer_gb = css_size_bytes / (1024 ** 3)
        js_transfer_gb = js_size_bytes / (1024 ** 3)
        media_transfer_gb = media_size_bytes / (1024 ** 3)

        return css_transfer_gb, js_transfer_gb, media_transfer_gb
    except Exception as e:
        print(f"Error processing {url}: {e}")
        return None

@app.get("/calculatecarbon/")
def calculatecarbon(web_url: str):
    """API Endpoint to calculate carbon footprint based on data transfer."""
    try:
        css_transfer_gb, js_transfer_gb, media_transfer_gb = calculate_data_transfer(web_url)
        total_data_gb = sum([css_transfer_gb, js_transfer_gb, media_transfer_gb])
        
        return {
            "url": web_url,
            "css_data_gb": css_transfer_gb,
            "js_data_gb": js_transfer_gb,
            "media_data_gb": media_transfer_gb,
            "total_data_gb": total_data_gb
        }
    except Exception as e:
        return {"error": str(e)}
