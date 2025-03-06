const String simpleManifestString = """
{
"ext_name": "simp",
"format": "open-board-0.1",
  "root": "simple.obf",
  "paths": {
     "boards": {
     "simple":"simple.obf" 
    }
  }
}
""";
const String manifestString = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "paths": {
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";
const String namedManifestString = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "ext_name": "simp",
  "paths": {
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";

const String toMergeString = """
{
  "format": "closed-board-0.1",
  "root": "boards/root_board.obf",
  "paths": {
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/lru_images.obf",
      "inline_images": "boards/inline_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";
const String merged = """
{
  "format": "closed-board-0.1",
  "root": "boards/root_board.obf",
  "paths": {
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/lru_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";

const String updatedPathsManifestString = """
{
  "format": "open-board-0.1",
  "root": "boards/rlu_images.obf",
  "paths": {
    "boards": {
      "absolute": "boards/rando.obf",
      "url_images": "boards/rlu_images.obf",
      "inline_images": "boards/hidden.obf",
      "images_and_sounds": "boards/secret.obf",
      "voclization": "boards/linked_board.obf"
    },
    "images": {
      "9": "images/unhappy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sighs.mp3"
    }
  }
}
""";
const String manifestStringWithExt = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "ext_hello": "true",
  "ext_bye": "false",
  "paths": {
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";
const String manifestStringWithPathExt = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "paths": {
    "ext_hidden": "hot dogs",
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";

const String idCollision = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "paths": {
    "boards": {
      "absolute1": "boards/root_board.obf",
      "absolute": "board/here",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";
const String fullExtendedPorpertiesManfiest = """
{
  "format": "open-board-0.1",
  "root": "boards/root_board.obf",
  "ext_hello": "true",
  "ext_bye": "false",
  "paths": {
    "ext_hotdog": "hidden",
    "boards": {
      "absolute": "boards/root_board.obf",
      "url_images": "boards/url_images.obf",
      "inline_images": "boards/inline_images.obf",
      "images_and_sounds": "boards/path_images.obf",
      "voclization": "boards/link.obf"
    },
    "images": {
      "9": "images/happy.png",
      "11": "images/sad.png"
    },
    "sounds": {
      "s1": "sounds/sigh.mp3",
      "s2": "sounds/sigh.mp3"
    }
  }
}
""";
