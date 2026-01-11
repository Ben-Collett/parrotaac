const catSearchResult = """[
{
    "id": 2217,
    "symbol_key": "cat-e58706c7",
    "name": "cat",
    "locale": "en",
    "license": "CC BY-NC-SA",
    "license_url": "http://creativecommons.org/licenses/by-nc-sa/3.0/",
    "enabled": true,
    "author": "Sergio Palao",
    "author_url": "http://www.catedu.es/arasaac/condiciones_uso.php",
    "source_url": null,
    "repo_key": "arasaac",
    "hc": false,
    "protected_symbol": false,
    "extension": "png",
    "image_url": "https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/cat.png",
    "search_string": "cat - , cat, tom , mittens, แมว, mean kitty song, penelope, sake, बिल्ली, the cat, sam a cat, what is a cat's favorite color?, katt, middy, catdo, kittens, a cat, fefe, misty, garfield, two lumps, kisa, kass, tako:s, lily, kitty , rhiow, snickers, good cat, قط, purple cat, , gato, kat, kitten, have, cat,",
    "unsafe_result": false,
    "_href": "/api/v1/symbols/arasaac/cat-e58706c7?id=2217",
    "details_url": "/symbols/arasaac/cat-e58706c7?id=2217",
    "use_score": 11,
    "relevance": 567.29684,
    "repo_index": 2
  }]
""";

const runSearchResult = """[
  {
    "id": 24181,
    "symbol_key": "run-3ae729c4",
    "name": "run",
    "locale": "en",
    "license": "CC BY-NC",
    "license_url": "http://creativecommons.org/licenses/by-nc/2.0/",
    "enabled": true,
    "author": "Sclera",
    "author_url": "http://www.sclera.be/en/picto/copyright",
    "source_url": null,
    "repo_key": "sclera",
    "hc": false,
    "protected_symbol": false,
    "extension": "png",
    "image_url": "https://d18vdu4p71yql0.cloudfront.net/libraries/sclera/run.png",
    "search_string": "run - , run , correr, stop, runs, to run, la fitness, run away baby, me, run,",
    "unsafe_result": false,
    "_href": "/api/v1/symbols/sclera/run-3ae729c4?id=24181",
    "details_url": "/symbols/sclera/run-3ae729c4?id=24181",
    "use_score": 4,
    "relevance": 222.86690666666667,
    "repo_index": 2
  },
  {
    "id": 47751,
    "symbol_key": "woman-running-d1f6fd4f",
    "name": "woman running",
    "locale": "en",
    "license": "CC BY",
    "license_url": "https://creativecommons.org/licenses/by/4.0/",
    "enabled": true,
    "author": "Twitter. Inc.",
    "author_url": "https://www.twitter.com",
    "source_url": "https://raw.githubusercontent.com/twitter/twemoji/gh-pages/svg/1f3c3-200d-2640-fe0f.svg",
    "repo_key": "twemoji",
    "hc": false,
    "protected_symbol": false,
    "extension": "svg",
    "image_url": "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-varxxxUNI-200d-2640-fe0f.svg",
    "search_string": "woman running - woman running, hurry, motion, run, 🏃‍♀️, 1f3c3-200d-2640-fe0f, takbo, hurry up, apúrate, running, motion, hurry, run,",
    "unsafe_result": false,
    "skins": true,
    "_href": "/api/v1/symbols/twemoji/woman-running-d1f6fd4f?id=47751",
    "details_url": "/symbols/twemoji/woman-running-d1f6fd4f?id=47751",
    "use_score": 8,
    "relevance": 147.43213333333333,
    "repo_index": 2
  }
  ]""";

//from second result of string above
const toneSupportingJson = {
  "id": 47751,
  "image_url":
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-varxxxUNI-200d-2640-fe0f.svg",
  "skins": true,
};
