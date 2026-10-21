import urllib.request

url = (
    "https://raw.githubusercontent.com/rfordatascience/tidytuesday/"
    "master/data/2020/2020-02-04/games.csv"
)
urllib.request.urlretrieve(url, "data/raw.csv")
