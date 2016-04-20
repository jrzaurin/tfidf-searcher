## to run, for example: Rscript query.r "science and religion or technology" 10 "TRUE"
suppressMessages(require(tm))
suppressMessages(require(SnowballC))

args = commandArgs(trailingOnly=TRUE)
load("model.rda")
q <- as.character(args[1])
k <- as.integer(args[2])
fixed <- as.logical(args[3])

query <- function(q,tfidftdm,k,fixed)
{
    ## q        : query
    ## tfidftdm : TermDocumentMatrix with tf-idf
    ## k        : number of documents to retrieve
    ## fixed    : strict (science -> science) or flexible search (science -> science, neuroscience, ...)
    
    ## implementing the logic
    ## 1- splitting the string on "OR" into AND logic blocks
    or.split <- unlist(strsplit(q, " or "))

    ## 2- group the terms queried via "AND" 
    terms.list <- sapply(or.split, function(x) strsplit(x, " and "))

    ## 3- Initializing the results vector and searching through every "logic
    ## block" ( -> "OR")
    results <- c()
    for (l in terms.list)
    {    
        # if we should match the query words.
        if (fixed){
            ## find the rows/words in the             
        rows <- which(rownames(tfidftdm) %in% l)
        
        ## if the word is not in the corpus, stop
        if(length(rows) == 0) stop("fixed Query: some of the inputs words are not in the corpus")            
        
        ## list of documents containing the words in the query
        docs <- list()
        for (r in rows)
        {
            sub.matrix <- as.matrix(tfidftdm[r,])
            d <- which(sub.matrix != 0)
            docs <- append(docs, list(d))
        }
        
        ## performing the "AND" logic by intersect the datasets
        cols <- Reduce(intersect, docs)
        
        }
        ## We add some flexibility to the search by also including documents
        ## that have words of a similar root than those in the query.
        ## For example, querying "science" will also consider "neuroscience"
        else
        {            

            ## list of documents containing the words in the query
            docs <- list()
            for (t in l)
            {                
                ## stemming the query-word(s) for flexible search 
                new.rows <- stemDocument(t)

                ## find the rows/words with "similar" words
                rows <- which(grepl(new.rows,rownames(tfidftdm)))

                ## if the word is not in the corpus, stop               
                if(length(rows) == 0) stop("Flexible Query: some of the inputs words are not in the corpus")            

                ## initialise an aggregator of all files with "similar" words
                agg <- c()
                for (r in rows)
                {                    
                    sub.matrix <- as.matrix(tfidftdm[r,])
                    d <- which(sub.matrix != 0)
                    agg <- unique(c(agg,d))
                    
                }

                docs <- append(docs,list(agg))
            } 
            
            ## performing the "AND" logic by intersect the datasets
            cols <- Reduce(intersect, docs)
        }
  
    }
                       
    ## 4-finally, adding the tfidf scores...
    scores <- apply(as.matrix(tfidftdm[rows,cols]), 2, sum)
    
    ## adding names to the vector...
    doc.names <- colnames(tfidftdm)[cols]
    names(scores) <- doc.names
    
    ## aggregating results..
    results <- c(results,scores)

    ## sorting results based on score, descending order...
    results <- sort(results, decreasing = TRUE)
    
    ## and drop duplicated from the "OR" join and return k documents
    is.duplicated <- which(duplicated(names(results)))
    if (any(is.duplicated))   results <- results[-is.duplicated]
    
    return(results[1:k])
        
}

res <- query(q,tfidftdm,k,fixed)
out.text <- paste(names(res), as.numeric(res), sep = ": ")
out.text <- paste(out.text, "\n")
cat(out.text, "\n")


