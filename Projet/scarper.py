import sqlite3
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# Chemin vers le pilote EdgeDriver, remplacez '/chemin/vers/votre/msedgedriver' par le chemin correct sur votre système
chrome_driver_path = "C:\\Users\\Mathis Delmaere\\Downloads\\chromedriver_win32\\chromedriver.exe"
service = Service(chrome_driver_path)

# Initialiser le navigateur Chrome avec le pilote Chrome WebDriver
driver = webdriver.Chrome(service=service)

# Ouvrir la page Letterboxd
driver.get("https://letterboxd.com/films/year/2000/by/release/")

# Attendre quelques secondes pour permettre le chargement de la page
time.sleep(5)

# Connexion à la base de données SQLite
conn = sqlite3.connect('bdd.sql')
c = conn.cursor()

# Liste pour stocker les liens
liens = []

# Boucle pour parcourir toutes les pages de films
for i in range(105):
    # Trouver tous les éléments avec la classe 'frame' (ce sont les liens des films)
    elements = driver.find_elements(By.XPATH, "//a[@class='frame']")
    for element in elements:
        # Récupérer le lien de chaque film
        lien = element.get_attribute("href")
        liens.append(lien)

    # Cliquer sur le bouton 'Suivant'
    driver.execute_script("window.scrollTo(0, 0);")
    next_button = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//a[@class='next']")))
    next_button.click()

    # Attendre quelques secondes avant de passer à la page suivante
    time.sleep(5)

    print(liens)

# Insérer les liens dans la base de données
for lien in liens:
    c.execute("INSERT INTO LiensFilms (lien) VALUES (?)", (lien,))

# Valider les changements et fermer la connexion à la base de données
conn.commit()
conn.close()

# Fermer le navigateur
driver.quit()
