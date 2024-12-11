from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException
import requests, os, logging
from urllib.parse import urlparse, urlunparse

class WebCrawler:
    def __init__(self, base_url, exclude_urls, driver_path=None, agent=None, include_domains=None, include_urls=None, include_urls_regex=None, ignore_anchor_link=False):
        chrome_options = Options()
        # Run Chrome in headless mode
        chrome_options.add_argument("--headless")

        # Disable GPU hardware acceleration
        chrome_options.add_argument("--disable-gpu")

        # Disable infobars on startup
        chrome_options.add_argument("--disable-infobars")

        # Disable notifications
        chrome_options.add_argument("--disable-notifications")

        # Disable pop-up blocking
        chrome_options.add_argument("--disable-popup-blocking")

        # Disable automatic software updates
        chrome_options.add_argument("--disable-software-rasterizer")

        # Disable prompt for user data sync
        chrome_options.add_argument("--disable-sync")

        # Disable translate UI
        chrome_options.add_argument("--disable-translate")

        # Disable save password bubbles
        chrome_options.add_argument("--disable-save-password-bubble")

        # Disable autoplay of embedded videos
        chrome_options.add_argument("--autoplay-policy=user-gesture-required")

        # Additional options to speed up Chrome
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")

        # Disable logging
        chrome_options.add_argument("--log-level=3")

        # Silent logging
        chrome_options.add_argument("--silent")

        # Set user agent
        chrome_options.add_argument(f'user-agent={agent}')

        self.driver = webdriver.Chrome(options=chrome_options)
        self.base_url = base_url
        self.exclude_urls = exclude_urls
        self.include_domains = include_domains
        self.include_urls = include_urls
        self.ignore_anchor_link = ignore_anchor_link
        self.include_urls_regex = include_urls_regex

    def visit_url(self, url):
        try:
            self.driver.set_page_load_timeout(20)  # Set timeout to 20 seconds
            self.driver.get(url)
        except TimeoutException as e:
            logging.error(f"Page load timed out for {url}, Exception: {e}")
        except Exception as e:
            logging.error(f"Error occurred while loading {url}, Exception: {e}")

    def get_page_source(self):
        return self.driver.page_source   


    def get_elements(self, strategy, element_selector):
        try:
            elements = self.driver.find_elements(strategy, element_selector)
            return elements
        except Exception as e:
            logging.error(f"Error: {e}")
            return None
        

    def parse_tables(self):
        tables = self.get_elements(By.TAG_NAME, "table")
        table_dict = {}

        for table in tables:
            rows = table.find_elements(By.TAG_NAME, "tr")
            header = []

            for row in rows:
                row_dict = {}
                row_dict["metadata"] = {}
                ref_links = []

                cols = row.find_elements(By.TAG_NAME,"td")

                key_links = []
                if cols:
                    key_links  = self.get_links(cols[0], exclude=True)
                    if key_links:
                        ref_links.extend(key_links)
                    elif len(cols) > 3:
                        key_links = self.get_solicitation_links(cols[3])

                    if len(cols) > 2:
                        ref_links.extend(self.get_links(cols[2], exclude=True))
                    if len(cols) > 3:
                        ref_links.extend(self.get_links(cols[3], exclude=True))
                
                if not header:
                    header = [col.text.strip() for col in row.find_elements(By.TAG_NAME,"th")]
                row_data = [col.text for col in cols]
                
                if row_data:
                    for i in range(len(header)):
                        if i < len(row_data):
                            row_dict["metadata"][header[i]] = row_data[i].strip()
                    
                    if ref_links:
                        deduped_links = list(set(ref_links))
                        row_dict["links"] = deduped_links

                    if row_dict and key_links:
                        table_dict[key_links[0].strip()] = row_dict

        return table_dict


    def get_links(self, element, exclude=False, file_types=None, include=True):
        links = []

        ref_links = element.find_elements(By.TAG_NAME, "a")

        raw_links = []

        if len(ref_links) > 0:
            for ref_link in ref_links:
                link = ref_link.get_attribute("href")
                raw_links.append(link)

                if link:
                    link = link.strip()
                    logging.debug(f"Link: {link}")
                else:
                    continue

                parsed_link = urlparse(link)

                if self.ignore_anchor_link:
                    parsed_link = parsed_link._replace(fragment='')
                    link = urlunparse(parsed_link)

                if not link and not parsed_link:
                    continue


                if not link.startswith('mailto:') and not (exclude and any(link.startswith(prefix) for prefix in self.exclude_urls)):
                    if self.include_domains and parsed_link.netloc.lower() not in self.include_domains:
                        continue

                    if include:
                        include_match = False

                        if self.include_urls_regex and any(pattern.fullmatch(link) for pattern in self.include_urls_regex):
                            logging.info(f"Link: {link} matched with one of include url regex")
                            include_match = True

                        if self.include_urls:
                            for include_url in self.include_urls:
                                logging.info(f"Comparing link: {link} with include url: {include_url}")
                                if link.lower().startswith(include_url):
                                    logging.info(f"Link: {link.lower()} matched include url: {include_url}")
                                    include_match = True
                                    break

                        if not include_match:
                            continue

                    if file_types:
                        for file_type in file_types:
                            logging.info(f"Link: {parsed_link.path.lower()} comparing with file type: {file_type}")
                            if parsed_link.path.lower().endswith(file_type):
                                links.append(link)
                                break
                            if file_type == 'html' and '.' not in parsed_link.path:
                                links.append(link)
                                break
                    else:
                        links.append(link)
        
        return self.remove_duplicate_links(links), raw_links
    
    def remove_duplicate_links(self, links):
        seen = set()
        unique_links = []
        for link in links:
            if link not in seen:
                unique_links.append(link)
                seen.add(link)
        return unique_links

    def get_solicitation_links(self, element):
        links = []

        ref_links = element.find_elements(By.LINK_TEXT, "Solicitation Document")

        if len(ref_links) > 0:
            for ref_link in ref_links:
                links.append(ref_link.get_attribute("href").strip())
        
        return links
    
    def get_pdf(self, url):
        response = requests.get(url)
        return response

    def parse_page(self):
        main_content = self.driver.find_element(By.TAG_NAME, "body")
        return main_content.text

    def close(self):
        self.driver.quit()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.driver.quit()
