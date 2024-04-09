from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Chemin du webdriver, assurez-vous de télécharger le bon pilote pour votre navigateur
# et de spécifier le chemin correct
PATH = "chemin_vers_le_webdriver"

# Initialisation du navigateur
driver = webdriver.Chrome(PATH)

# URL de la page à scraper
url = "https://letterboxd.com/films/popular/"
driver.get(url)

# Attendre que la liste des films soit chargée
wait = WebDriverWait(driver, 10)
wait.until(EC.visibility_of_element_located((By.CLASS_NAME, "film-poster")))

# Récupérer tous les liens vers les pages de films
film_links = []
while True:
    film_posters = driver.find_elements_by_class_name("film-poster")
    for film_poster in film_posters:
        film_link = film_poster.find_element_by_tag_name('a').get_attribute('href')
        film_links.append(film_link)
    
    # Vérifier si il y a une page suivante
    next_button = driver.find_element_by_xpath("//a[@class='next']")
    if 'disabled' in next_button.get_attribute('class'):
        break
    else:
        next_button.click()

# Fermer le navigateur
driver.quit()

# Afficher les liens vers les pages de films
for link in film_links:
    print(link)
