# Palindrome generator
This program generates palindromes randomly using a dictionary and/or a language model.

Exported from Google Code (https://code.google.com/archive/p/palindrome-generator/)


## What is it?

A program to generate palindromes in the language of your choice. Hopefully even a few that will make sense and not consist of nothing but word salad.

## What do I need to do to run it?

At least a word list in your language, stored in a text file that the program can consult when producing the palindromes. Apart from a plain word list, if you have access to word frequency counts, even better. If you have a list of 2-word sequences along with their frequencies of occurrence, much better.

## How do I run it?

The simplest usage is something like:

`pg.perl -m 50 -1 wordlist.txt`

Assuming wordlist.txt is a list of words in your target language, one word on each line, this command will spit out palindromes all day for you, in this case all of maximum length 50 characters (controlled by the -m flag). If you're only using a simple word list, most of them won't make any sense whatsoever, which is why you should read on...

## Using more advanced language models

To increase the chances of generating palindromes that make sense, the generator can be combined with a crude language model that will steer the generator toward more "plausible" sentences. In this case, the language model will be a "n-gram model" that takes advantage of the frequency of occurrence of words and substrings to constrain the sentence generation. You can supply counts of single words (1-grams), two-word sequences (2-grams), or three-word sequences (3-grams) in text files to provide this information. Such data is simple to collect from any text corpus - a dump of Wikipedia, for example (most likely a partial dump). See the downloads directory for example files. These files are to be in a simple tabular format with words and counts separated by tabs. A 1-gram count file would look like so:

`the 59417 of 28419 to 27443 a 24781 in 21041 and 20435 ...`

A two-gram file like so (the #-symbol indicates a sentence boundary):

`...`

`the 8062`

`of the 6249 in the 5365`

`in 2144`

`said # 2210 ... `

And a three-gram file like so:

`...`

`it is 58984`

`one of the 33119`

`in the 32730`

`...`

You can now run pg.perl with the following options, for example:

`pg.perl -m 50 -2 2grams.txt`

Note, however, that a fairly large corpus must be used to collect the counts from, even for 2-grams. Even so, it's a good idea to convert all words to lower case, prune the list of punctuation, prune the list of acronyms (which may be frequent, but which are mostly useless in palindromes). In short, having a good, clean, wordlist is key to generating sensible palindromes.

## More options

### Repetition

By default, the program will not repeat words in a sentence. You can disable this behavior completely with the flag -R "*". However, if you do, you may end up with a lot of monotone sequences "a a a a," especially if you're using only a unigram model.

You can also fine-tune this option to only allow for repetition of certain words (common function words most likely). For example, if we wanted to allow for several occurrences of "the", "and", "of", "a", "an", and "in" we could issue something like:

`pg.perl -R "the and of a on in" [more options]`

### Starting with a palindrome seed

Sometimes you run across a palindrome that looks promising - i.e., one that starts well and ends well - and that you want to explore some more. You can force the generator to only generate palindromes that start or end in a certain way by issuing the flags -l "string" or -r "string".

Suppose, for instance, that you are bent on exploring potential palindromes that start with the word "sex". This you can do by

`pg.perl -l "sex" [more options]`

Suppose further that you now discover that "taxes" would be a sound and logically coherent way to end a palindrome starting with "sex" - as opposed to "faxes", "telexes" or "fixes", among other things - you can now issue:

pg.perl -l "sex" -r "taxes" [more options]

Doing this repeatedly is a good way to give "artistic direction" to the generator and eventually end up with a killer palindrome. As you run pg like this, you'll probably discover an even longer sequence that looks promising, and that you can then lock on to using the -l or -r options.

### Weighting by sequence frequency

The program by default will generate palindromes randomly (given the word sequence constraints) where the randomness is biased so that words that are longer get selected more often. You can change this behavior with the flag -f which says that pg should weight the random generator to generate word sequences that are more frequent with regard to the word sequence counts provided.

### Controlling restarts

The program will by default generate 20 palindromes from where it started (which are all going to look alike), and then automatically restart with something else as the first word. You can change this using the -s flag. For example:

`pg.perl -l "sex" -r "taxes" -s 1000 -1 wsj1grams.txt`

would generate 1,000 palindromes, each one longer than the previous, and then start over with just "sex" and "taxes".

### How does the algorithm work?

The algorithm maintains two strings, called L and R, which start off empty and together represent the entire palindrome, which is a concatenation of L and R. It then calls itself recursively while adding suitable material to L or R. On each call it calculates the "overhang" between L and reverse(R), creates a list of words that match the suffix or prefix of the overhang, and calls itself, adding the new word to either L or R, depending on which is shorter. The overhang is calculated by removing spaces, aligning both strings, and producing the remainder. For example, overhang(abcd, ab) = cd.

### See also

A somewhat similar method for finding palindromes (interestingly enough formalized as a finite-state machine) is attributed to Dan Hoey in the 1992 book Expert C Programming by Peter van der Linden, though the original code appears to be unavailable.

Peter Norvig expanded on Hoey's work in his article World's Longest Palindrome Sentence; here the focus was on creating long palindromes in the mold "A man, a plan, a canal, ..., Panama!" If you're interested in this particular genre, you can also launch pg into a frenzy of spitting out long palindromes of that type by issuing:

`pg.perl -l "a man a plan a canal" -r "panama" -s 100000 -m 100000 -1 wordlist.txt`

MH20130228
