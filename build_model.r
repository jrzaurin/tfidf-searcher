## to run: Rscript build_model.r dirname
suppressMessages(require(tm))
suppressMessages(require(SnowballC))

options(mc.cores=1)

args = commandArgs(trailingOnly=TRUE)
dir <- args[1]

clean.docs <- function(dir, stem = FALSE)
{
    ## Function to acess to the documents, clean the content and return a corpus
    ## ready for processing
    ##dir: directory containing the docs
    ##stem: optional stemization

    ## Build a corpus assuming english language
    fnames <- DirSource(dir,encoding = "UTF-8", recursive=TRUE)
    corpus <- Corpus(fnames, readerControl=list(reader=readPlain,language="en"))

    ## Map the cleaning task for speed:
    ## 1- Remove non alphabetical characters
    corpus <- tm_map(corpus, function(x) gsub("[^[:alpha:]]", " ", x))

    ## 2- all to lower case
    corpus <- tm_map(corpus, tolower)

    ## 3- Remove Punctuation
    corpus <- tm_map(corpus, removePunctuation)

    ## 4- Strip WhiteSpaces
    corpus <- tm_map(corpus, stripWhitespace)

    ## 5- if steming is TRUE, apply stemization
    if (stem) corpus <- tm_map(corpus, stemDocument)

    ## 6- mapping into adequate format for TermDocumentMatrix
    corpus <- tm_map(corpus, PlainTextDocument)    
    
    return(corpus)

} 

tfidTDM <- function(dir, corpus)
{
    
    ## 1- Grabbing the filenames that will be the column names later for convenience
    fnames <- DirSource(dir,encoding = "UTF-8", recursive=TRUE)
    fnames.list <- fnames$filelist

    ## 2- Building term (rows) document (columns) matrix.
    ##    NOTE: weightTfIdf normalises by default
    tfidftdm <- TermDocumentMatrix(corpus, control=list(stopwords=TRUE,
                                                        weighting=weightTfIdf))

    ## 3- Setting colnames to documen names 
    colnames(tfidftdm) <- fnames.list

    ## 4- removing from the matrix unsually long terms
    ##    "unusual" is defined as greater than mean(number of characters) + 3*std
    words <- rownames(tfidftdm)
    meanchar <- mean(nchar(words))
    stdchar <- sd(nchar(words))
    max.numb.chars <- meanchar + 3*stdchar
    drop.words <- which(nchar(words) > max.numb.chars)

    ## there are only 753 unusal long words to drop
    tfidftdm <- tfidftdm[-drop.words,]
    
    return(tfidftdm)
}

corpus <- clean.docs(dir)
tfidftdm <- tfidTDM(dir, corpus)
save(tfidftdm, file = "model.rda")
