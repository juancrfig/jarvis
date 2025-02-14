from selenium import webdriver
from selenium.webdriver.common.by import By
import time

# Setup Chrome options
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

# Open a new Chrome window
driver = webdriver.Chrome(options=chrome_options)

# Open the login page
driver.get("https://camper.campuslands.com/")

# Wait for manual login
input("Log in manually, then press Enter to continue...")

# Wait 5 seconds after pressing Enter
time.sleep(5)

# Navigate to the target page
driver.get("https://camper.campuslands.com/skills")

# Wait for the page to load
time.sleep(5)

try:
    # Find the parent container
    parent_div = driver.find_element(By.CLASS_NAME, "el-scrollbar__view")
    
    # Find all child divs with class 'd-middle w-full gap-x-5'
    child_divs = parent_div.find_elements(By.CLASS_NAME, "d-middle.w-full.gap-x-5")

    if len(child_divs) < 2:
        print("Not enough elements found!")
    else:
        last_div = child_divs[-1]  # Get the last div
        second_last_div = child_divs[-2]  # Get the second-to-last div

        # Check if the last div contains a <p> with "Software Saturdays"
        try:
            p_element = last_div.find_element(By.TAG_NAME, "p")
            if "Software Saturdays" in p_element.text.strip():
                print("Found 'Software Saturdays' in the last div. Clicking the second-to-last div instead.")
                second_last_div.click()
            else:
                print("Last div does not contain 'Software Saturdays'. Clicking it.")
                last_div.click()
        except:
            print("No <p> element found in the last div. Clicking it.")
            last_div.click()

    print("Correct div clicked!")

    # Wait for the next page to load
    time.sleep(5)

    while True:  # Main loop that continues until no more buttons are found
        # Check for buttons with the given classes
        buttons = driver.find_elements(By.CLASS_NAME, "btn-secondary-short.f-12.hf-24px.wf-76px")

        if not buttons:
            print("No more buttons found. Process complete!")
            break

        print(f"Found {len(buttons)} buttons. Processing the first one...")
        buttons[0].click()

        # Wait for the next page to load
        time.sleep(5)

        try:
            # Find all elements that have at least the specified classes
            elements = driver.find_elements(By.CSS_SELECTOR, ".transition-all.ease-linear.duration-150.icon-happy-outline")

            if elements:
                print(f"Found {len(elements)} elements with the specified classes. Clicking each one...")
                for element in elements:
                    element.click()
                    time.sleep(0.5)  # Small delay between clicks
            else:
                print("No elements found with the specified classes.")
        except Exception as e:
            print(f"Error finding or clicking elements: {e}")

        # Click the final button to proceed
        try:
            next_button = driver.find_element(By.CSS_SELECTOR, ".btn-medium.w-fit.mt-14")
            if next_button:
                print("Next button found! Clicking it...")
                next_button.click()
                # Wait for the page to load back
                time.sleep(5)
            else:
                print("No next button found!")
                break
        except Exception as e:
            print(f"Error finding or clicking the next button: {e}")
            break

except Exception as e:
    print(f"Error: {e}")

# Keep browser open for testing
time.sleep(500)

# Remove or comment out the following line to keep the browser open
# driver.quit()