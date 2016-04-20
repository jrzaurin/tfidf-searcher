# tfidf-searcher
Simple tf-idf searcher in R

## Usage
### To clean the text and build the model use build_model.r

```
Rscript build_model.r dirname
```

For example

```
Rscript build_model.r 20_newsgroups
```

This will create a `.rda` file in your working directory with the TermDocumentMatrix

### To search given a query (logical queries supported), use query.r 

```
Rscript query.r query k fixed
```

where:

```
query : string corresponding to the search query
k     : integer of document to retrieve
fixed : logical indicating where the search is "fixed" (e.g. science -> science) or whether we allow for 
        some flexibility (e.g. science -> science, neuroscience, ...)
```

For example:

```
Rscript query.r "science and religion or technology" 10 "TRUE"
```

## What's Next

The quickest and most straightforward approach to improve the search would be to pre-process the text better. 
For example, correcting for joined words that might affect the search (e.g. "computerscience"), or correct 
misspelled words. Another example is using a-priori knowledge on the nature of the documents. In this particular
case the corpus are emails, and R and python both come with libraries to parse this format so one would not process
the headers. Finally, in the documents there is a line such as: "Line: 622" that indicates the length of the body. 
In a preprocessing phase one could use this information to just concentrate on the body. 

Nonetheless, even with a good pre-processing a caveat remains on whether or not tf-idf is a good approach to retrieve
documents in this and similar cases. If the queries are simply keywords, tf-idf will ultimately on the frequency of 
the word in a document. Instead, these keywords will usually be associated to topics in and the search should be faced as such. Here I describe some additional strategies to further improve document retrieval given a short query. 

### Word Vectors to find similar words

This approach consist of: 1) compute the word vectors using Word2Vec and a large corpus or use pre-trained vectors (for example Google Vectors), 2) given a query find similar terms to those in the query and 3) search for all these terms in a similar way to that describe in the script query.r. Note that this approach would only add a few lines of code to 
the scripts described above.

For example, let's use we can use word2vec in ``gensim``, in python along the google vectors and this 3 lines of code will 
already illustrate the use of this approach: 

```
from gensim.models import word2vec
import logging
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s',level=logging.INFO)
model = word2vec.Word2Vec.load_word2vec_format('GoogleNews-vectors-negative300.bin', binary=True)
model.most_similar('science')[:10]

(u'faith_Jezierski', 0.6965422034263611),
 (u'sciences', 0.68210768699646),
 (u'biology', 0.6775784492492676),
 (u'scientific', 0.6535002589225769),
 (u'mathematics', 0.6300909519195557),
 (u'Hilal_Khashan_professor', 0.6153368949890137),
 (u'impeach_USADA', 0.6149060726165771),
 (u'professor_Kent_Redfield', 0.6144177913665771),
 (u'physics_astronomy', 0.6105073690414429),
 (u'bionic_prosthetic_fingers', 0.6083078980445862)]
```

The Google vectors were computed without cleaning. Given that word2vec is *highly* dependent on the corpus we can see that 
the results are a little "funny". This would be solved either by post processing or by building a specialized corpus. 

### Word Vectors with vector quantization (BoW with word vectors)

This approach consist of: 1) compute the word vectors using Word2Vec and a large corpus or use pre-trained vectors (for example Google Vectors), 2) run a clustering algorithm to build a vocabulary. This could run on top of a tf-idf or a bm25 metric to prune corpus. 3) Perform vector quantization, i.e. project the words in each document onto the vocabulary space and 4) given a query, project the query onto the vocabulary space and search for similar documents.

Again, this approach might not be adequate if the queries consist always of a very small collection of keywords

### Topic Modelling

Since topics is what we are looking for, this would be perhaps my favorite approach. This approach consists of: 1) run a topic modelling algorithm (e.g. LDA or CMT) on the corpus with certain number of topics, 2) the result of this would be an object with information of the words associated to each topic an a metric corresponding how "strongly" a word contributes to a topic. For example given a model called `lda` obtained using `gensim` in python, and a syntax like the following, will retrieve the mentioned information: 

```
lda.print_topics(1)
topic #0: 0.005*science + 0.001*sea + ... + 0.011*religion + ...
```

NOTE: same could be attained using the `topicmodels` package in R.

and 3) given a query, assign that to a topic and retrieve the documents where that topic is the most frequent. In reality this approach allows for some flexibility in addressing how the information is retrieved. 

### Others

We can turn this into a supervised task, here are two ways to do that:

#### Others.1

For example 1) based on prior knowledge we define a topic scheme comprising n-number of topics, 2 )one could use a platform like Amazon Mechanical Turk and present the user with a series of documents that he/she would have to label according to that topic scheme. 3) Use Doc2Vec, the deep learning implementation of paragraph2vec in `gensim` to compute paragraph vectors (again, we need a large corpus), 4) use this feature-vectors, along with a classification algorithm to train a model.

A minor limitation is that in this case, future users could only chose from a limited number of topics

#### Others.2

Finally, the final goal here is to build a recommendation system. In any recommendation system user information is the most relevant information. Therefore, one could use historical data on queries and retrieve documents to build a model. For example, let's say that a user searches for "science" and we have successfully recommend 6 out of 10 recommendations (here success would be opening and spending X amount of time on the document). Given the feature-vectors associated to the document, computed with any of the approaches defined above, and the user "journey" through the service/platform, we could build a matrix with user and item profiles that can be used to apply any of the well known recommendation techniques. 

Hope this is useful.