from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import requests

app = FastAPI()

# ✅ Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with your frontend domain for security
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Constants
NON_RENEW_ENERGY_TO_CARBON = 441  # g/kWh
RENEW_ENERGY_TO_CARBON = 50       # g/kWh
DATA_TO_ENERGY = 0.81             # kWh/GB

# Global request settings (important for Vercel timeouts)
REQUEST_TIMEOUT = 4
HEADERS = {"User-Agent": "Mozilla/5.0"}

def fetch_resource_size(resource_url: str) -> int:
    """Fetch the size of an external resource (CSS, JS, images, etc.)."""
    try:
        response = requests.get(
            resource_url,
            timeout=REQUEST_TIMEOUT,
            headers=HEADERS,
            stream=True
        )
        if response.status_code == 200:
            content_length = response.headers.get("Content-Length")
            if content_length:
                return int(content_length)
            return len(response.content)
    except Exception:
        return 0
    return 0

def getsource(tag):
    """Extract the correct source URL from different HTML attributes."""
    for attr in ["src", "href", "data-src", "poster"]:
        src = tag.get(attr)
        if src and not src.startswith("data:image/"):
            return src
    return None

def calculate_data_transfer(url: str):
    """Scrape website data transfer details."""
    try:
        response = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers=HEADERS
        )
        if response.status_code != 200:
            return (0, 0, 0, 0, 0)

        soup = BeautifulSoup(response.text, "html.parser")
        html_size_bytes = len(response.text)

        css_size = js_size = media_size = 0

        # Limit assets to prevent timeout on large sites
        for link in soup.find_all("link", rel="stylesheet")[:10]:
            src = getsource(link)
            if src:
                css_size += fetch_resource_size(urljoin(url, src))

        for script in soup.find_all("script")[:10]:
            src = getsource(script)
            if src:
                js_size += fetch_resource_size(urljoin(url, src))

        for media in soup.find_all(["img", "video", "audio"])[:10]:
            src = getsource(media)
            if src:
                media_size += fetch_resource_size(urljoin(url, src))

        return (
            css_size / (1024 ** 3),
            0,  # Fonts not tracked
            js_size / (1024 ** 3),
            media_size / (1024 ** 3),
            html_size_bytes / (1024 ** 3),
        )
    except Exception:
        return (0, 0, 0, 0, 0)

def check_green_website(url: str) -> bool:
    """Check if a website is hosted on green energy."""
    try:
        domain = urlparse(url).netloc
        api_url = f"https://api.thegreenwebfoundation.org/api/v3/greencheck/{domain}"
        response = requests.get(api_url, timeout=REQUEST_TIMEOUT)
        if response.status_code == 200:
            return response.json().get("green", False)
    except Exception:
        pass
    return False

def calculate_carbon(data_gb: float, green: bool) -> float:
    """Calculate the carbon footprint based on data usage."""
    factor = RENEW_ENERGY_TO_CARBON if green else NON_RENEW_ENERGY_TO_CARBON
    return factor * DATA_TO_ENERGY * data_gb

@app.get("/calculate_footprint")
def calculate_footprint(
    web_url: str = Query(..., title="Website URL", description="URL of the website to analyze")
):
    """API endpoint to calculate website carbon footprint."""
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
        "carbon_footprint": carbon,
        "green_hosting": green,
    }
