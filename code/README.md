# Code
There are some pre-requisites to be able to run the pyhton code:
- [Golang](https://go.dev/dl/): this is necessary for the Awpy library to work. Must be version 1.17 or above. Make sure to add Go to PATH.
- [Awpy library](https://awpy.readthedocs.io/en/latest/installation.html): this is the main library used to parse the demo files. The author is [Peter Xenopoulos](http://www.peterxeno.com/), who was very kind to not only make the library public but also to help me when I run into some troubles using it. I ran all my code using version 1.3 of the awpy library.

Once both are installed, you should be able to run `Updated_parser`, provided in the folder `code`.
#### Updated_parser.ipynb
---

The first code block defines some functions to be used later. The functions were given to me by Peter Xenopoulos, I only made a couple of minor modifications.

After that, there are two main code blocks. The first one goes through all the demo files and parses them, creating a `.json` file for each demo. The second block gathers match and round characteristics, including chat messages where the word pause or tech was used, and writes to `parsed.xlsx`.

#### updated.do
---
The `updated.do` file contain the code used to clean de data and create the tables/ figures in the thesis. All tables and figures are exportex as .tex files onto the `output` folder.
