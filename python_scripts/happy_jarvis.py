#!/usr/bin/env python3

from selenium import webdriver
from selenium.webdriver.common.by import By
import time
import random

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

# Navigate to the calificaciones page
driver.get("https://camper.campuslands.com/calificaciones")

# Wait for the page to load
time.sleep(2)

while True:
    # Find all "Calificar" buttons
    calificar_buttons = driver.find_elements(By.XPATH, "//button[contains(@class, 'btn-short') and text()='Calificar']")
    
    if not calificar_buttons:
        print("No more 'Calificar' buttons found. Process complete!")
        break
    
    print(f"Found {len(calificar_buttons)} 'Calificar' buttons. Processing the first one...")
    calificar_buttons[0].click()
    
    # Wait for the next page to load
    time.sleep(2)
    
    try:
        # List of possible face adjectives
        face_adjectives = ["happy", "midhappy", "serious", "sad"]
        
        # Randomly select a face adjective for this iteration
        selected_adjective = random.choice(face_adjectives)
        print(f"Randomly selected face type: {selected_adjective}")
        
        # Find all elements with the selected face adjective
        css_selector = f".transition-all.ease-linear.duration-150.icon-{selected_adjective}-outline"
        elements = driver.find_elements(By.CSS_SELECTOR, css_selector)
        
        if elements:
            print(f"Found {len(elements)} {selected_adjective} face elements. Clicking each one...")
            for element in elements:
                element.click()
                time.sleep(0.1)  # Small delay between clicks
        else:
            print(f"No {selected_adjective} face elements found on this page.")
    except Exception as e:
        print(f"Error finding or clicking face elements: {e}")
    
    # Click the final button to proceed (using the same selector as in the original script)
    try:
        next_button = driver.find_element(By.CSS_SELECTOR, ".btn-medium.w-fit.mt-14")
        if next_button:
            print("Next button found! Clicking it...")
            next_button.click()
            # Wait for the page to load back
            time.sleep(2)
        else:
            print("No next button found!")
            break
    except Exception as e:
        print(f"Error finding or clicking the next button: {e}")
        # Go back to the calificaciones page
        driver.get("https://camper.campuslands.com/calificaciones")
        time.sleep(5)

# Keep browser open for testing
input("Press Enter to close the browser...")
