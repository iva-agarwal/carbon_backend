from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware  # Import CORS Middleware
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import requests

app = FastAPI()

# ✅ Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with ["https://eco2info.netlify.app"] for more security
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Constants
nonrenw_energytocarbon = 441  # g/kWh
renw_energytocarbon = 50  # g/kWh
datatoenergy = 0.81  # kWh/GB

def fetch_resource_size(resource_url):
    """Fetch the size of an external resource (CSS, JS, images, etc.)."""
    try:
        response = requests.get(resource_url, timeout=5)
        if response.status_code == 200:
            content_length = response.headers.get('Content-Length')
            return int(content_length) if content_length else len(response.content)
    except Exception:
        return 0
    return 0

def getsource(tag):
    """Extract the correct source URL from different HTML attributes."""
    for attr in ['src', 'href', 'data-src', 'poster']:
        src = tag.get(attr)
        if src and not src.startswith("data:image/"):
            return src
    return None

def calculate_data_transfer(url):
    """Scrape website data transfer details (CSS, JS, images)."""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code != 200:
            return (0, 0, 0, 0, 0)

        html_content = response.text
        soup = BeautifulSoup(html_content, 'html.parser')

        html_size_bytes = len(html_content)
        css_size_bytes = js_size_bytes = media_size_bytes = 0

        for link_tag in soup.find_all('link', rel='stylesheet'):
            src = getsource(link_tag)
            if src:
                css_size_bytes += fetch_resource_size(urljoin(url, src))

        for script_tag in soup.find_all('script'):
            src = getsource(script_tag)
            if src:
                js_size_bytes += fetch_resource_size(urljoin(url, src))

        for media_tag in soup.find_all(['img', 'video', 'audio']):
            src = getsource(media_tag)
            if src:
                media_size_bytes += fetch_resource_size(urljoin(url, src))

        return (
            css_size_bytes / (1024 ** 3),  # Convert bytes to GB
            0,  # Font size not tracked
            js_size_bytes / (1024 ** 3),
            media_size_bytes / (1024 ** 3),
            html_size_bytes / (1024 ** 3)
        )
    except Exception:
        return (0, 0, 0, 0, 0)

def check_green_website(url):
    """Check if a website is hosted on green energy."""
    parsed_url = urlparse(url).netloc
    api_url = f"https://api.thegreenwebfoundation.org/api/v3/greencheck/{parsed_url}"
    try:
        response = requests.get(api_url, timeout=5)
        return response.json().get("green", False) if response.status_code == 200 else False
    except Exception:
        return False

def calculate_carbon(data, green):
    """Calculate the carbon footprint based on data usage."""
    energy_factor = renw_energytocarbon if green else nonrenw_energytocarbon
    return energy_factor * datatoenergy * data

@app.get("/calculate_footprint")
def calculate_footprint(web_url: str = Query(..., title="Website URL", description="URL of the website to analyze")):
    """API endpoint to calculate website carbon footprint."""
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
