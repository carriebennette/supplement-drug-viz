# Visualizing supplement-drug interactions in the scientific literature

I first found the [suppAI](https://supp.ai/) when the Allen Institute for AI posted an announcement on Twitter. It seemed like a really interesting corpus of scientific evidence regarding interactions of dietary and herbal supplements with each other and with prescription and over-the-counter medications. I played around with the online search functionality, but something felt missing.  I really want to get an overall sense of the data in a way that manually plugging in various supplemnet names wasn't providing.  I was also interested in flexing my data visualization muscles so decided I would try to visualize the connections.  

# Raw data preparation

## Using SuppAI's data and API

SuppAI kindly provides free (and really easy to use!) access to it's underlying data via [download](https://api.semanticscholar.org/supp/legal/) and an [API](https://supp.ai/docs/api).  I initially wanted to download the data, but it turns out the API contains additional variables that I needed (most notably the agent's "preferred name") so I ended up using a combination.  If I was starting over from scratch I'd do everything using only the API to simplify things a bit. 

## Supplement classifications

Once I got the raw SuppAI into R and started trying to plot it, I realized that there were A LOT of supplements, but no real way to organize them meaningfully. I needed a way to group the various agents. I did some research and found 2 useful resources. The first was a JAMA publication on the [Trends in Dietary Supplement Use Among US Adults From 1999-2012](https://jamanetwork.com/journals/jama/fullarticle/2565748).  It listed dozens of the most commonly used supplements and provided some high-level organization to the different types of supplements (e.g., vitamin, mineral, fatty acid, botancial, etc).  I categorized the remaining supplements using data from the [Dietary Supplemental Label Databse](https://dsld.nlm.nih.gov/dsld/). The Dietary Supplemental Label Databse includes products on market, off market, and those consumed by NHANES survey participants. Supplements that weren't included in either database (e.g., cocaine, ethanol, and glucose) were excluded. 

## Anatomical Therapeutic Chemical (ATC) Classification 

I initially used the Anatomical Therapeutic Chemical (ATC) classification system, which groups the active substances according to the to the organ or system on which they act and their therapeutic, pharmacological and chemical properties.  Finding a relatively clean dataset that included all ATC codes _and_ all CUI (Concept Unique Identifier) codes (used by SuppAI) was tricky (a bunch I discovered early were incomplete), but I eventually found a complete list as part of the [National Center for Biomedical Ontology](https://bioportal.bioontology.org/ontologies/ATC). BioPortal seems like a really valuable resource and I hope to explore it more fully in the future. After getting all the data linked, I realized that a lot of drugs were cross-listed (i.e., they were used in multiple organ systems or had several distinct therapeutic uses). So I didn't end up using the ATC data, but including details here as I did go through the effort of cleaning and processing the data (see some older commits for details).

# Data visualization preparation

## Matrix flow

Getting the data into a format that would work with D3 turned out to be more of a challenge than I expected.  I still haven't mastered working with JSON data (or manipulating data with D3/Javascript) so I tried to keep as much of the data prepration as possible within R.  I end up creating a flow matrix to represent the bidirectional "flow" connecting two agents within the dataset (i.e., a supplement and drug or a 2 supplements) where the "flow" represents the number of scientific papers reporting an interaction of those agents.  As noted on the SuppAI website, the number of papers reporting an interaction is not a proxy for the strength of the actual interaction (nor does absence of a connection indicate that the supplement, drug or combination is safe or appropriate). 

## Focusing on 'stronger' connections

I really wanted to show "everything" in a single figure. Part of what impressed me about the database curated by AI2 was it's sheer size and complexity and I wanted to capture that visually.  When I created the figure that included everything, however, I quickly realized that there were tons of very weak connections that made the figure look messier than I had hoped.  You could tell things were complex, but you couldn't really see the important patterns amidst all the tiny lines going everywhere.  So I decided to focus only on interactions with at an interaction reported in at least 25 papers.  This change made the visualizing much more visually appealing and helps viewers see some of the patterns across the overall dataset more easily.



