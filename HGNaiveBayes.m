//
//  HGNaiveBayes.m
//  HGNaiveBayes
//
//  Created by Henrique Galo on 4/20/14.
//  Copyright (c) 2014 Henrique Galo. All rights reserved.
//  Long time ago.
//

#import "HGNaiveBayes.h"

@implementation HGVersion

- (instancetype)init {
    if (self == NULL) {
        self = [super init];
    }
    
    self.major = 0;
    self.minor = 0;
    self.revision = 0;
    
    return self;
}

@end

@implementation HGNaiveBayes

#pragma mark - Initialization

- (NSString*)groupIdentifier {
    return @"your.app.identifier"; //if using App-Groups of iOS 8.
}

- (NSURL*)libraryAddress {
    return [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self groupIdentifier]] URLByAppendingPathComponent:@"Documents" isDirectory:TRUE] URLByAppendingPathComponent:@"database.plist"];
}

- (instancetype)init {
    if (self == NULL) {
        self = [super init];
    }
    
    self.numberOfTags = 0;
    self.numberOfLearnedPhrases = 0;
    
    listOfWords = [[NSMutableDictionary alloc] init];
    listOfCategories = [[NSMutableDictionary alloc] init];
    
    if ([self.libraryAddress checkResourceIsReachableAndReturnError:nil]) {
        NSMutableDictionary *library = [[NSMutableDictionary alloc] initWithContentsOfURL:self.libraryAddress];
        
        listOfWords = [library objectForKey:@"listOfWords"];
        listOfCategories = [library objectForKey:@"listOfCategories"];
        self.numberOfTags = [[library objectForKey:@"numberOfTags"] integerValue];
        self.numberOfLearnedPhrases = [[library objectForKey:@"numberOfPhrases"] integerValue];
        
        if ([library objectForKey:@"libraryVersion"] == nil) {
            
            NSString *libraryVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", [[self naiveLibraryVersion] major], [[self naiveLibraryVersion] minor], [[self naiveLibraryVersion] revision]];
            [library setObject:libraryVersion forKey:@"libraryVersion"];
            [library writeToURL:self.libraryAddress atomically:TRUE];
        }

    }
    else {
        NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
        NSString *libraryVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", [[self libraryVersion] major], [[self libraryVersion] minor], [[self libraryVersion] revision]];
        [library setObject:libraryVersion forKey:@"libraryVersion"];
        [library writeToURL:self.libraryAddress atomically:TRUE];
    }
    
    return self;
}

+ (instancetype)sharedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (instancetype)initAndDownloadXML:(NSURL*)url categoryOfXML:(NSString *)category {
    if (self == NULL) {
        self = [super init];
    }
    
    self.numberOfTags = 0;
    self.numberOfLearnedPhrases = 0;
    listOfWords = [[NSMutableDictionary alloc] init];
    listOfCategories = [[NSMutableDictionary alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self downloadDatabaseFromURL:url categoryOfXML:category];
    });
    
    return self;
}

- (instancetype)initWithOtherLibrary:(NSDictionary*)library {
    if (self == NULL) {
        self = [super init];
    }
    
    listOfWords = [library objectForKey:@"listOfWords"];
    listOfCategories = [library objectForKey:@"listOfCategories"];
    self.numberOfTags = [[library objectForKey:@"numberOfTags"] integerValue];
    self.numberOfLearnedPhrases = [[library objectForKey:@"numberOfPhrases"] integerValue];
    
    return self;
}

#pragma mark - Download
- (void)downloadDatabaseFromURL:(NSURL *)url categoryOfXML:(NSString *)category  {

    NSData *data = [NSData dataWithContentsOfURL:url];
    self.xmlCategory = category;
    
    if(data != nil){
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        
        [parser setDelegate:self]; // The parser calls methods in this class
        [parser setShouldProcessNamespaces:NO]; // We don't care about namespaces
        [parser setShouldReportNamespacePrefixes:NO]; //
        [parser setShouldResolveExternalEntities:NO]; // We just want data, no other stuff
        
        [parser parse]; // Parse that data..
    }
}

#pragma mark - NSXMLParserDelegate
-(void)  parser: (NSXMLParser *) parser didStartElement: (NSString*) elementName namespaceURI: (NSString*) namespaceURI qualifiedName: (NSString*) qualifiedName attributes: (NSDictionary*) attributeDict
{
    self.xmlTag = elementName;
    currentWebPage = [[NSMutableString alloc] init];;
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"description"]) {
        [self convertHTMLDocumentToPlainAndTrain:currentWebPage category:self.xmlCategory];
    }
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if(currentWebPage == nil) {
        currentWebPage = [[NSMutableString alloc] init];
    }

    [currentWebPage appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
    [library setObject:listOfCategories forKey:@"listOfCategories"];
    [library setObject:listOfWords forKey:@"listOfWords"];
    [library setObject:[NSNumber numberWithInteger:self.numberOfTags] forKey:@"numberOfTags"];
    [library setObject:[NSNumber numberWithInteger:self.numberOfLearnedPhrases] forKey:@"numberOfPhrases"];
    
    if ([library writeToURL:self.libraryAddress atomically:TRUE]) {
    }
    
}

- (void)convertHTMLDocumentToPlainAndTrain:(NSString*)doc category:(NSString*)docCategory {
    NSAttributedString *phraseString = [[NSAttributedString alloc] initWithData:[doc dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    
    [self trainDatabaseWithPhrase:[self wordsOfPhrase:phraseString.string] andCategory:docCategory forced:FALSE];
}

#pragma mark - Training Methods
- (void)trainDatabaseWithPhrases:(NSArray*)phrases withCategories:(NSArray*)categories {
    if ([phrases count] != [categories count]) {
        NSLog(@"failed");
        return;
    }
    else {
        for (int i = 0; i < [phrases count]; i++) {
            NSArray *phrase = [self bagOfWords:[phrases objectAtIndex:i]]; //removing duplicates
            self.numberOfLearnedPhrases++;
            
            for (int j = 0; j < phrase.count; j++) {
                [self addWord:[phrase objectAtIndex:i] andCategory:[categories objectAtIndex:j] manually:FALSE];
            }
        }
    }
}

- (void)trainDatabaseWithPhrase:(NSArray*)phrase andCategory:(NSString*)category forced:(BOOL)isForced {
    phrase = [self bagOfWords:phrase]; //removing duplicates
    self.numberOfLearnedPhrases++;
        
    for (int i = 0; i < phrase.count; i++) {
        if (isForced) {
            [self addWord:[phrase objectAtIndex:i] andCategory:category manually:TRUE];
        }
        else {
            [self addWord:[phrase objectAtIndex:i] andCategory:category manually:FALSE];
        }
    }
    
    if (isForced) {
        NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
        [library setObject:listOfCategories forKey:@"listOfCategories"];
        [library setObject:listOfWords forKey:@"listOfWords"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfTags] forKey:@"numberOfTags"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfLearnedPhrases] forKey:@"numberOfPhrases"];
        
        if ([library writeToURL:self.libraryAddress atomically:TRUE]) {
        }
    }
}

- (void)trainDatabaseManually:(NSArray*)phrase newCategory:(NSString*)category {
    phrase = [self bagOfWords:phrase];
    self.numberOfLearnedPhrases++;

    for (int i = 0; i < phrase.count; i++) {
        [self addWord:[phrase objectAtIndex:i] andCategory:category manually:TRUE];
    }
}

- (void)addWord:(NSString*)word andCategory:(NSString*)cat manually:(BOOL)manual
{
    word = [word lowercaseString];
//    cat = [cat lowercaseString]; /* MODIFIED TO MEET APP REQUIREMENTS */
    
    if (listOfWords == nil) {
        listOfWords = [[NSMutableDictionary alloc] init];
    }
    
    if ([listOfWords objectForKey:word] == nil) {
        [listOfWords setObject:[NSMutableDictionary dictionary] forKey:word];
        
        if (manual) {
            [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1000.0f] forKey:cat];
        }
        else {
            [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1.0f] forKey:cat];
        }
    }
    else {
        if ([[listOfWords objectForKey:word] objectForKey:cat] == nil) {
            if (manual) {
                [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1000.0f] forKey:cat];
            }
            else {
                [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1.0f] forKey:cat];
            }
        }
        else {
            double numOfTimes = [[[listOfWords objectForKey:word] objectForKey:cat] doubleValue];
            if (manual) {
                numOfTimes += 1000;
            }
            else {
                numOfTimes++;
            }
            
            [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:numOfTimes] forKey:cat];
        }
    }
    
    if ([[listOfWords objectForKey:word] objectForKey:@"total"] == nil) {
        if (manual) {
            [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1000.0f] forKey:@"total"];
        }
        else {
            [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:1.0f] forKey:@"total"];
        }
    }
    else {
        double totalTimes = [[[listOfWords objectForKey:word] objectForKey:@"total"] doubleValue];
        if (manual) {
            totalTimes += 1000;
        }
        else {
            totalTimes++;
        }
        [[listOfWords objectForKey:word] setObject:[NSNumber numberWithDouble:totalTimes] forKey:@"total"];
    }
    
    self.numberOfTags++;
    
    if (listOfCategories == nil) {
        listOfCategories = [[NSMutableDictionary alloc] init];
    }
    
    
    if ([listOfCategories objectForKey:cat] == nil) {
        if (manual) {
            [listOfCategories setObject:[NSNumber numberWithDouble:1000.0f] forKey:cat];
        }
        else {
            [listOfCategories setObject:[NSNumber numberWithDouble:1.0f] forKey:cat];
        }
    }
    else {
        double numOfTimes = [[listOfCategories objectForKey:cat] doubleValue];
        if (manual) {
            numOfTimes += 1000;
        }
        else {
            numOfTimes++;
        }
        
        [listOfCategories setObject:[NSNumber numberWithDouble:numOfTimes] forKey:cat];
    }
}

#pragma mark - Classifications
- (NSString *)classifyPhrase:(NSArray*)phrase {
    CGFloat max = -CGFLOAT_MAX;
    
    NSString *bestCategory = [[NSString alloc] init];
    
    for (NSString *category in [listOfCategories allKeys]) {
        CGFloat categoryScore = 0.0f;
        CGFloat phraseScore = 0.0f;
        CGFloat pCategory = [self pCategory:category];

        for (NSString *word in phrase) {
            CGFloat prob = [self pCategoryForWord:word category:category];
            phraseScore += log(prob);
        }
        
        categoryScore = (log(pCategory) + (phraseScore));
        
        if (categoryScore > max) {
            max = categoryScore;
            bestCategory = category;
        }
    }
    
    if (max == NAN || max == 0.0f || max == -CGFLOAT_MAX) {
        bestCategory = @"other";
    }
    
    [self trainDatabaseWithPhrase:phrase andCategory:bestCategory forced:FALSE];
    
    return bestCategory;
}

- (NSArray *)probabilitiesForPhrase:(NSArray*)phrase {
    CGFloat max = -CGFLOAT_MAX;

    NSMutableArray *orderedProbabilities = [[NSMutableArray alloc] init];
    
    for (NSString *category in [listOfCategories allKeys]) {
        CGFloat categoryScore = 0.0f;
        CGFloat phraseScore = 0.0f;
        CGFloat pCategory = [self pCategory:category];
        
        for (NSString *word in phrase) {
            CGFloat prob = [self pCategoryForWord:word category:category];
            phraseScore += log(prob);
        }
        
        categoryScore = (log(pCategory) + (phraseScore));
        
        NSMutableDictionary *probabilities = [[NSMutableDictionary alloc] init];
        [probabilities setObject:[NSNumber numberWithFloat:categoryScore] forKey:category];
        [orderedProbabilities addObject:probabilities];

        if (categoryScore > max) {
            max = categoryScore;
            [orderedProbabilities exchangeObjectAtIndex:0 withObjectAtIndex:([orderedProbabilities count] - 1)];
        }
    }
    
    return orderedProbabilities;
}

#pragma mark - Probabilities
- (double)pCategoryForWord:(NSString*)word category:(NSString*)cat {
    CGFloat probability = 0.f;
    
    if ([[listOfWords objectForKey:word] objectForKey:cat] != NULL) {
            CGFloat wordInCategory = ([[[listOfWords objectForKey:word] objectForKey:cat] doubleValue] + (float)[listOfWords count] * (1.f / (float)[listOfWords count]));
            
            CGFloat categoryTimes = ([[listOfCategories objectForKey:cat] doubleValue] + [listOfWords count]);
            
            probability = (wordInCategory / categoryTimes);
    }
    else {
        CGFloat wordInCategory = (0.f + (float)[listOfWords count] * (1.f / (float)[listOfWords count]));
        
        CGFloat categoryTimes = ([[listOfCategories objectForKey:cat] doubleValue] + (float)[listOfWords count]);
        
        probability = (wordInCategory / categoryTimes);
    }
    
    return probability;
}

- (double)pCategory:(NSString*)cat {
    if ([listOfCategories objectForKey:cat] != nil) {
        return ([[listOfCategories objectForKey:cat] doubleValue] / (float)[self numberOfWordsInAllCategories]);
    }
    else {
        return 0.f;
    }
}

- (double)numberOfWordsInAllCategories {
    double numberOf = 0.00;
    for (int i = 0; i < listOfCategories.count; i++) {
        numberOf += [[listOfCategories objectForKey:[[listOfCategories allKeys] objectAtIndex:i]] doubleValue];
    }
    return numberOf;
}

- (double)pWord:(NSString*)word
{
    if (word != nil) {
        return [[[listOfWords objectForKey:word] objectForKey:@"total"] doubleValue] / (float)self.numberOfTags;
    }
    else {
        return 0.0f;
    }
}

- (BOOL)removeCategory:(NSString*)category numOfPhrases:(NSInteger)numOfPhrases {
    if ([listOfCategories objectForKey:category] != nil) {

        [listOfCategories removeObjectForKey:category];

        for (NSString *word in [listOfWords allKeys]) {
            if ([[listOfWords objectForKey:word] objectForKey:category] != nil) {
                NSInteger numberCategory = [[[listOfWords objectForKey:word] objectForKey:category] integerValue];
                NSInteger total = [[[listOfWords objectForKey:word] objectForKey:@"total"] integerValue];
                
                self.numberOfTags--;
                
                [[listOfWords objectForKey:word] removeObjectForKey:category];
                
                total -= numberCategory;
                
                [[listOfWords objectForKey:word] setObject:[NSNumber numberWithInteger:total] forKey:@"total"];
            }
        }

        self.numberOfLearnedPhrases -= numOfPhrases;
        
        NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
        [library setObject:listOfCategories forKey:@"listOfCategories"];
        [library setObject:listOfWords forKey:@"listOfWords"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfTags] forKey:@"numberOfTags"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfLearnedPhrases] forKey:@"numberOfPhrases"];
        
        if ([library writeToURL:self.libraryAddress atomically:TRUE]) {
        }
        
        return TRUE;
    }
    else {
        return FALSE;
    }
}

- (NSArray*)wordsInCategory:(NSString*)category {
    NSIndexSet *indexSet = [[listOfWords allValues] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *myObject = (NSMutableDictionary *)obj;

        NSInteger index = [[myObject allKeys] indexOfObject:category];

        return index != NSNotFound ? TRUE:FALSE;
    }];
    
    return [[listOfWords allKeys] objectsAtIndexes:indexSet];
}

- (BOOL)removeWords:(NSArray*)words from:(NSString *)category {

    if ([listOfCategories objectForKey:category] != nil) {
        
        NSArray *wordsCategory = [self wordsInCategory:category];
        
        NSIndexSet *indexSet = [wordsCategory indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            NSString *myObject = (NSString*)obj;
            
            NSInteger index = [words indexOfObject:myObject];
            
            return index != NSNotFound ? TRUE:FALSE;
        }];
        
        NSArray *eligibleWords = [wordsCategory objectsAtIndexes:indexSet];
        
        [wordsCategory enumerateObjectsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSInteger categoryNumber = [[listOfCategories objectForKey:category] integerValue];

            NSString *key = (NSString*)obj;
            
            NSInteger numberCategory = [[[listOfWords objectForKey:key] objectForKey:category] integerValue];
            NSInteger total = [[[listOfWords objectForKey:key] objectForKey:@"total"] integerValue];

            [[listOfWords objectForKey:key] removeObjectForKey:category];

            categoryNumber -= numberCategory;
            total -= numberCategory;

            [[listOfWords objectForKey:key] setObject:[NSNumber numberWithInteger:total] forKey:@"total"];
            [listOfCategories setObject:[NSNumber numberWithInteger:categoryNumber] forKey:category];
        }];
        
        self.numberOfTags -= [eligibleWords count];
        self.numberOfLearnedPhrases--;
        
        NSLog(@"here %@", category);
        NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
        [library setObject:listOfCategories forKey:@"listOfCategories"];
        [library setObject:listOfWords forKey:@"listOfWords"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfTags] forKey:@"numberOfTags"];
        [library setObject:[NSNumber numberWithInteger:self.numberOfLearnedPhrases] forKey:@"numberOfPhrases"];
        
        if ([library writeToURL:self.libraryAddress atomically:TRUE]) {
        }
        
        return TRUE;
    }
    else {
        return FALSE;
    }
}

#pragma mark - Tools
- (NSArray *)bagOfWords:(NSArray*)array
{
    NSCountedSet *cSet = [[NSCountedSet alloc] initWithArray:array];
    return [cSet allObjects];
}

- (NSArray *)wordsOfPhrase:(NSString *)phrase
{
    phrase = [phrase lowercaseString];
    return [self bagOfWords:[phrase componentsSeparatedByString:@" "]];
}

- (NSArray*)allCategories {
    NSMutableDictionary *library = [[NSMutableDictionary alloc] initWithContentsOfURL:self.libraryAddress];
    listOfCategories = [library objectForKey:@"listOfCategories"];
    return (listOfCategories != nil) ? [listOfCategories allKeys] : [NSArray array];
}

- (NSInteger)countForWord:(NSString*)word {
    return ([listOfWords objectForKey:word] != nil) ? [[listOfWords objectForKey:word] integerValue] : 0;
}

- (void)printSession {

    NSLog(@"\n------- HGNB sharedInstance Session -------- \n\nHGNB Version %ld.%ld.%ld\n\n\nNumber Of Words: %ld\nNumber Of Phrases: %ld\n", [[self naiveVersion] major], [[self naiveVersion] minor], [[self naiveVersion] revision], self.numberOfTags, self.numberOfLearnedPhrases);
}

- (HGVersion*)libraryVersion {
    NSMutableDictionary *library = [[NSMutableDictionary alloc] initWithContentsOfURL:self.libraryAddress];
    
    NSString *versionString = [library objectForKey:@"libraryVersion"];
    NSArray *numbers = [versionString componentsSeparatedByString:@"."];
    
    HGVersion *version = [[HGVersion alloc] init];
    version.major = [[numbers firstObject] integerValue];
    version.minor = [[numbers lastObject] integerValue];
    version.revision = 0;
    
    return version;
}

- (HGVersion*)naiveLibraryVersion {
    NSString *versionString = [NSString stringWithFormat:@"%.1f", currentLibraryVersion];
    NSArray *numbers = [versionString componentsSeparatedByString:@"."];
    
    HGVersion *version = [[HGVersion alloc] init];
    version.major = [[numbers firstObject] integerValue];
    version.minor = [[numbers lastObject] integerValue];
    version.revision = 0;
    
    return version;
}

- (HGVersion*)naiveVersion {
    NSString *versionString = [NSString stringWithFormat:@"%.1f", HGNBVersion];
    NSArray *numbers = [versionString componentsSeparatedByString:@"."];
    
    HGVersion *version = [[HGVersion alloc] init];
    version.major = [[numbers firstObject] integerValue];
    version.minor = [[numbers lastObject] integerValue];
    version.revision = HGNBRevision;
    
    return version;
}


@end
