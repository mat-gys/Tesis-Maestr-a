[![DOI](https://zenodo.org/badge/506765367.svg)](https://zenodo.org/badge/latestdoi/506765367)


In this repository, you'll find the replication files for my UdeSA Master's thesis:

# The Effect of Timeouts on Team Performance: Evidence from E-sports

## Data
The file `final` in the `ouput` folder has all the data necessary to run the dofile regressions.

Files containing match information, downloaded from [HLTV](https://www.hltv.org/results), were too large to include in github. They are available in my [DropBox](https://www.dropbox.com/sh/zbx6g8yjy4d1c7i/AAD_wY3Cp0cWY9mIHYtlmvRSa?dl=0). Once you download the files, you should place them in the `input` folder. If you wish to store it in another folder, you'll have to manually change the _path_to_demos_ variable provided in the code to your prefered folder location.
Take into account, since some variables had to be included manually, that the last columns in `parsedDemos.xlsx` should not be altered. There's a backup file in the main folder if needed.

I've made copies of every main file in the version used to create this thesis; they are available in the `output` folder. The file `winProbDemos.xlsx` received some by-hand modifications after running the code that outputs the file. In particular, some demos were divided in two parts. I searched for this demos by looking por the word "p1". I then made sure the matchID was identical within a game and that the round numbers were correct.

## Code
There are some pre-requisites to be able to run the pyhton code:
- [Golang](https://go.dev/dl/): this is necessary for the Awpy library to work. Must be version 1.17 or above. Make sure to add Go to PATH.
- [Awpy library](https://awpy.readthedocs.io/en/latest/installation.html): this is the main library used to parse the demo files. The author is [Peter Xenopoulos](http://www.peterxeno.com/), who was very kind to not only make the library public but also to help me when I run into some troubles using it. I ran all my code using version 1.2.1 of the awpy library.

Once both are installed, you should be able to run all of the code provided in the folder `code`.
#### DemoParser.ipynb
---
There are two main code blocks. The only difference is that the second one assumes the .rar files were extracted whilst the first one extracts them for you.

Both write a .xlsx file to the `output` folder named `parsedDemos`. In it, there are match and round characteristics, including round number, matchID, score, etc.

#### RoundWinProbabilityPredictor.ipynb
---
The first code block defines some functions to be used later. The functions were given to me by Peter Xenopoulos, I only made a couple of minor modifications.

After that, there are two main code blocks. The only difference is that the second one assumes the .rar files were extracted whilst the first one extracts them for you.

Both write a .xlsx fle to the `output` folder named `winProb`. In it, there are match and round characteristics from the previous round. These are going to be used as controls in the regressions.

At the end of the file, there are some block codes that merge `parsedDemos.xlsx` and `winProb.xlsx` into another file named `final.xlsx`, also in the `output` folder.

#### .do files
---
The .do files contain the code used to clean de data (in `clean_data.do`), and create the tables in the thesis (in `V2.do`). All tables are exportex as .tex files onto the `output` folder.

## Data structure example
The file `Data structure example.png` is an image that displays a visualization of the data structure that the awpy library produces. The example is reduced to the minimum information required to understand the structure. Every frame contains more information on every player of each team.
