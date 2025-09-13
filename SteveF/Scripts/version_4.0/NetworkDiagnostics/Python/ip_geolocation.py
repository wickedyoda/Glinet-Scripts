import requests
import datetime

def run_ip_geolocation_test(logpath):
    try:
        response = requests.get("http://ip-api.com/json", timeout=5)
        response.raise_for_status()
        data = response.json()

        geo_info = {
            "IP": data.get("query"),
            "Country": data.get("country"),
            "Region": data.get("regionName"),
            "City": data.get("city"),
            "ISP": data.get("isp"),
            "Org": data.get("org"),
            "Lat": data.get("lat"),
            "Lon": data.get("lon"),
        }

        output = (
            f"IP: {geo_info['IP']}\n"
            f"Country: {geo_info['Country']}\n"
            f"Region: {geo_info['Region']}\n"
            f"City: {geo_info['City']}\n"
            f"ISP: {geo_info['ISP']}\n"
            f"Org: {geo_info['Org']}\n"
            f"Lat: {geo_info['Lat']}\n"
            f"Lon: {geo_info['Lon']}"
        )

        with open(logpath, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.datetime.now()}] --- IP Geolocation ---\n")
            f.write(output + "\n")

        print("\n--- IP Geolocation ---")
        print(output)
        return geo_info

    except Exception as e:
        error_msg = f"Failed to retrieve IP geolocation: {e}"
        print(error_msg)
        with open(logpath, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.datetime.now()}] {error_msg}\n")
        return None
