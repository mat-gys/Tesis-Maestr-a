In this repository, you'll find the replication files for my Master's thesis "Does Momentum Matter? The Effect of Timeouts on Team Performance: Evidence from E-sports".

# Data
The file 'final' in the 'ouput' folder has all the data necessary to run the dofile regressions.

Files containing match information, downloaded from [HLTV](https://www.hltv.org/results), were too large to include in github. They are available in my [DropBox](linktodropbox). Once you download the files, you should place them in the 'parsedDemos' folder. If you wish to store it in another folder, you'll have to manually have the _path_to_demos_ variable provided in the code to your prefered folder location.
Take into account, since some variables had to be included manually, that the last 7 columns in 'parsedDemos.xlsx' should not be altered.


# Code
There are some pre-requisites to be able to run the code:
- [Golang](https://go.dev/dl/): this is necessary for the Awpy library to work. Must be version 1.17 or above. Make sure to add Go to PATH.
- [Awpy library](https://awpy.readthedocs.io/en/latest/installation.html): this is the main library used to parse the demo files. The author is [Peter Xenopoulos](http://www.peterxeno.com/), who was very kind to not only make the library public but also to help me when I run into some troubles using it. I ran all my code using version 1.1.9 of the awpy library.

Once both are installed, you should be able to run all of the code provided in the folder 'codigo'.
## DemoParser.ipynb
There are two main code blocks. The only difference is that the second one assumes the .rar files were extracted whilst the first one extracts them for you.

Both write a .xlsx file to the 'output' folder named 'parsedDemos'. In it, there are match and round characteristics, including round number, matchID, score, etc.

## RoundWinProbabilityPredictor.ipynb
The first code block defines some functions to be used later. The functions were given to me by Peter Xenopoulos, I only made a couple of minor modifications.

After that, there are two main code blocks. The only difference is that the second one assumes the .rar files were extracted whilst the first one extracts them for you.

Both write a .xlsx fle to the 'output' folder named 'winProb'. In it, there are match and round characteristics from the previous round. These are going to be used as controls in the regressions.

At the end of the file, there are some block codes that merge 'parsedDemos.xlsx' and 'winProb.xlsx' into another file named 'final.xlsx', also in the 'output' folder.

## reg.do
This is the replication file for the regressions. It imports the 'final.xlsx', clean it, creates the relevant variables, and then runs the regressions. The regression tables are exported into the 'output' folder into a latex and a text file named main_reg. This is the 'Main specification table' in the thesis.
