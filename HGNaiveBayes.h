//
//  HGNaiveBayes.h
//  HGNaiveBayes
//
//  Created by Henrique Galo on 4/20/14.
//  Copyright (c) 2014 Henrique Galo. All rights reserved.
//

#define HGNBVersion 2.3
#define HGNBRevision 4

#define currentLibraryVersion 2.3

#import "HGNaiveBayesTagTableViewController.h"

/*
 
 --------------------------------------------------------------------------------------------------------------------------------

 Changelog:
 - Version 1.0
    • First version
 
 - Version 1.0.1
    • First version adapted for CMM
 
 - Version 1.1
    • Algorithm updated
    • More accurate
 
 - Version 1.1.1
    • Updated for CMM
 
 - Version 1.2
    • Algorithm even more accurate
 
 - Version 1.2.1
    • Bug fixed
 
 - Version 1.3
    • New way to download pages from web
    • Saving only when the document is finished (faster!)
 
 - Version 1.3.1
    • New way to turn sentences into an array of words
 
 - Version 1.3.2
    • Learns in every new classification
 
 - Version 1.4 (Warning! Future versions of HGNaiveBayes may not work with libraries from older versions.)
    • Algorithm Updated
    • Manually Training 
    • Number Of Phrases
    • Runtime initWithDownloaded: changed to initAndDownloadXML:
    • Added Documentation
    • Disables Learning from every new classification (Will be back in 1.4.1)
 
 - Version 1.4.1
    • Learning from every new classification enabled
    • List of categories is private (Use [session allCategories] to get the categories outside the class)
 
 - Version 1.5
    • Deprecated classifyPhrase method (Read documentation for alternative)
    • New methods to classify phrases
 
 - Version 2.0 [Read recommendations before using new methods]
    • [Added] -(instancetype)sharedManager (now, HGNaiveBayes can be across all your classes)
    • [Modified] -(id)init merged with - (id)initWithSavedDatabase
    • [Modified] -(id)init to -(instancetype)init
    • [Modified] - (id)initAndDownloadXML
    • [Added] Dynamic Libraries (set libraryPath to work with. Otherwise, standard will be used)
    • [Added] - (instancetype)initWithOtherLibrary to work with Dynamic Libraries
 
 - Version 2.1 [Read recommendations before using new methods]
    • [Added] - (BOOL)removeWords:(NSArray*)words from:(NSString *)category
    • [Added] - (BOOL)removeCategory:(NSString*)category
 
 - Version 2.2
    • [Added] - (NSArray*)wordsInCategory:(NSString*)category
    • [Modified] - (BOOL)removeWords:(NSArray*)words from:(NSString *)category rewritten from ground.
    • [Removed] - (NSString *)classifyPhrase:(NSArray*)phrase (Deprecated since 1.5)
 
 - Version 2.2.1 [Read recommendations before updating]
    • [Modified] Category names are now case-sensitive.
 
 - Version 2.3 [Based on 2.2.1 - Read 2.2.1 change-log before upgrading]
    • [Added] HGVersioningSystem. A better way to manage deprecated.
    • [Added] - (HGVersion *)libraryVersion. Using library version.
    • [Added] - (HGVersion *)naiveLibraryVersion. Library version that HGNB will create.
    • [Added] - (HGVersion *)naiveVersion. HGNB Version.
    • [Added] Library updated. Includes library version for better upgrade methods.
    • [Modified] Automatic learning enabled. Read more on comments.
 
 - Version 2.3.1
 • [Added] - (void)printSession It prints the current state of the sharedInstance.
 
 - Version 2.3.2 (*)
 • [Fixed] Bug that prevented -(BOOL)removeCategory to discount numberOfPhrases - Bug since 2.1 (numberOfPhrases is no longer reliable. It is not possible to recount. - Read comment for this version BEFORE or if you're deciding to UPGRADE)
 
 ----------------
 Current Stable Version:
 
 - Version 2.3.4
    • [Added] Saving content on iCloud
    • [Added] - (NSURL*)libraryAddress
 
 -----------------
 Coming Soon:
 
 - Version 2.3.5
    • [Added] Automatic Backup methods and retrieve methods
    • [Modified] Library2,4 will now be standard. Library2,4 upgrades automatically and fully support 2,3 working libraries.
 
 - Version 2.4 (*) [Read recommendations before updating]
    • [Modified] - (void)trainDatabaseWithPhrase:(NSArray*)phrase andCategory:(NSString*)category forced:(BOOL)isForced caseSensitive:(BOOL)cs;
    • [Modified] - (void)trainDatabaseWithPhrases:(NSArray*)phrases withCategories:(NSArray*)categories caseSensitive:(BOOL)cs;
    • [Modified] - (void)trainDatabaseManually:(NSArray*)phrase newCategory:(NSString*)category caseSensitive:(BOOL)cs;
    • [Modified] - (void)downloadDatabaseFromURL:(NSURL*)url categoryOfXML:(NSString *)category caseSensitive:(BOOL)cs;
    • [Modified] - (instancetype)initAndDownloadXML:(NSURL*)url categoryOfXML:(NSString *)category caseSensitive:(BOOL)cs;
    • [Added] - (NSString *)categoryForPhrase:(NSArray*)phrase
 
 --------------------------------------------------------------------------------------------------------------------------------

 Library Support:
 
 Version        Built-in HGNB Version      HGNB Version Rollback    Library Version Upgrade     Library Legacy Compatibility    Library Auto-Backup
 ----------------------------------------------------------------------------------------------------------------------------------------------------
 Library1,0 |   1.0 ~ 1.3.2             |           x              |        x                 |             x                 |           x
 Library2,0 |   1.4.0                   |           x              |        √ (2,1 and 2,2)   |             x                 |           x
 Library2,1 |   1.4.1 ~ 1.5             |           x*             |        √ (2,2)           |             x                 |           x
 Library2,2 |   2.0 ~ 2.2.1             |           x**            |        x** (2,3)         |             x                 |           x
 Library2,3 |   2.3 ~ 2.3.2             |           x**            |        √                 |             √                 |           x
 Library2,4 |   2.3.3                   |           √              |        -                 |             √                 |           √
 
 If rollback is available, use initWithOtherLibrary. Not all features may be available. (initWithOtherLibrary - HGNB 1.4.0 and later)
 If upgrade is available, HGNB will do automatically. Make backup before updating.
 
 Upgrade to 2,3 is not obligatory. It does not include logical changes or new features, the ONLY difference is the version control. You can upgrade 2,2 libraries to 2,3 WITHOUT upgrading the code. Just add a "version" key in your library and the version (e.g. 2.2) as value. By adding the version key, HGNB will JUMP the 2,3 upgrade. THE UPGRADE IS NOT NEEDED. 2,3 IS INTERNALLY 2,2! The only difference between versions is the versioning system. So, by adding the key following the pattern (x.x.x) all the new methods MUST WORK normally.
 
 To know the HGNB and Library version, check new 2.3 methods.
 
 The 2.3.1 new method (printSession) is NOT printing the library version. Fix coming in next version.
 
 * Rollback not available due major bug in HGNB 1.4 and Library2,0.
 ** Turned off due major bug in versions 2.1 ~ 2.3.1. Read 2.3.1 comments for more details. (Library2,2 in versions BEFORE 2.1 are available for Rollback and Upgrade)
 
 --------------------------------------------------------------------------------------------------------------------------------
 
 Comments:
 [Beta - 1.0 ~ 1.3.2]
 - (Older versions) No support is available to older versions.
 
 [1.x - 1.4.1 ~ 1.5]
 - (Version 1.4.x) Library changes were needed. Beta versions are not supported, so to upgrade, you need to understand the changes between 1.3.2 to 1.4.x. It is recommended to wipe and start over. 1.3.2 does not have any major bug, you can still using but it is no longer supported.
 - (Version 1.4.x) NEVER roll back to 1.4.0. It will lose data due a bug fixed in 1.4.1.
 - (Version 1.5) classifyPhrase is deprecated. Use - (NSArray *)probabilitiesForPhrase:(NSArray*)phrase instead. It will be removed soon. (Read Version 2.2 recommendation for better understanding)
 
 [2.x - 2.0 ~ 2.3.1]
 - (Version 2.0) Do not use init instances and sharedManager instances. Prefer sharedManager. (Update will fix this)
 - (Version 2.1) Do not attempt to do removal in methods that are on background or that will be used frequently. It may considerably slow your program.
 - (Version 2.2) classifyPhrase is now unavailable. Use - (NSArray *)probabilitiesForPhrase:(NSArray*)phrase instead. No logic change needed in your program. Internal logic were changed back in 1.5 and probabilities provide a better way. To get the best like classifyPhrase just use [probabilitiesForPhrase firstObject]. The order is defined.
 - (Version 2.2) This version updated all remove methods. It is up to twice as fast than before, but stills lag in intense usage. Make sure to check performance before.
 - (Version 2.2.1) This build was built only for News Prototype. If you want to stay with 2.2.1 and use a non case-sensitive category name, please make it lowercase BEFORE adding. Library Upgrade is not needed.
 - (Version 2.2.1) 2.4 will make case-sensitive optional. No bugs or problems were fixed in 2.2.1. There is no real need to update. Also, 2.2 stills supported (2.2 STILLS SUPPORTED. 2.2.1 IS NO LONGER SUPPORTED.). Check for (*) in version history to see if it is supported.
 - (Version 2.3) Adds a entire new way to check versions in Libraries and object. It will be better to upgrade in future. All upgrades will be automatically and rollback is also available.
 - (Version 2.3) When we developed the 2.0 version, we had to start from scratch. We learned a lot from 1.4.0, so we decided it was time to roll back everything. And since 2.0 beta, learning from new classifications were disabled due a major bug in the connection between HGNB and library2,2, but this was FIXED since version 2.0 FINAL and the reason is that we almost forgotten in DISABLED status. Looking forward to release 2.3 we DECIDED to check all methods and we saw that automatic was DISABLED so we decided to ENABLE it again to see how it was going to work with 2,3 and worked perfectly. We doesn't recommend to force enable in older versions AS WE DON'T KNOW WHAT MAY HAPPEN. If you want to use the automatic learning, please update to 2.3. FORCE ENABLING MAY CORRUPT YOUR LIBRARY.
 - (Version 2.3.1) Adds printSession that shows at a glance everything happening on the instance.
 - (Version 2.3.1) Version 2.2.1 is no longer supported.
 - (Version 2.3.1) In a 2.3 comment we talked about 2.0 development. And 2.3.1 now provides the reason we had to start all over again. The older versions supported less words/phrases per file space and 2,0 library version broght an internal difference that is seen today as wise. In the 2.3.1 build we ran on a library with 30461 words and 65 phrases using a file small as 1.5MB. Such an amazing work.
 - (Version 2.3.2) [READ ALL COMMENTS BEFORE UPGRADING!!!] Fixed a MAJOR bug that causes HGNaiveBayes to be NOT reliable counting the number of phrases. It is HIGHLY recommended to upgrade as we decided to DROP all support for older versions due this bug. ONLY 2.3.2 software and Library2,3 will have support. Library2,3 provides Library Legacy Compatibility that let Library2,3 works in HGNB versions BEFORE 2.1 if needed. You MUST to start libraries from GROUND UP if the libraries were created or modified in HGNB versions 2.1 ~ 2.3.1 to have reliable numberOfPhrases. If it is IMPOSSIBLE to roll over, you can use numberOfWords as a numberOfPhrases parameter if necessary (IT IS IMPORTANT TO MAKE THE CHANGE IN LIBRARY BEFORE RUNNING THE SOFTWARE), but IT IS NOT RECOMMENDED as HGNB USES numberOfPhrases AS A IMPORTANT LIBRARY MANAGER NUMBER. HGNB Version Rollback for ALL LIBRARIES THAT SUPPORT VERSIONS BEFORE 2.3.2 WILL NO LONGER RECEIVE SUPPORT AND ROLLBACK/UPGRADE IS NO LONGER SUPPORTED. CHECK TABLE FOR DETAILS ABOUT VERSIONING.
 - (Version 2.3.2) As Library2,2 is no longer supported, Library2,3 is now OBLIGATORY for running HGNB. The upgrade WILL be automatically if you chose to keep the library. Read the other comment BEFORE upgrading. It is highly recommended to start over again.
 - (Version 2.3.2) Before upgrading CHECK if your library has problems. IF YOU DON'T USE removeCategory OR IT IS WORKING, YOU STILL NEED TO UPGRADE TO 2.3.2 BUT START OVER WILL NOT BE NECESSARY IN THOSE CASES.
 - (Version 2.3.2) BEFORE upgrading, it is recommended to BACKUP all libraries and AFTER upgrading CHECK if removeCategory IS WORKING PROPERLY. IN SEVERAL TESTS 2.3.2 FIXED ALL ISSUES, BUT IT IS STILL IMPORTANT TO CHECK IF IT IS WORKING BEFORE COMPROMISING LIBRARIES. VERSION 2.3.3 WILL BRING BACKUP FEATURES. 2.3.2 WAS BAKED REALLY QUICKLY.
 - (Version 2.3.3) NO NEED TO UPGRADE LIBRARY. ALL LIBRARIES ARE GOING TO BE AUTOMATICALLY SYNCED THROUGH iCLOUD.
 - (Version 2.3.3) YOU CAN CHOOSE TO save the library LOCALLY or on the iCLOUD.
 - (Pre-Version 2.3.4) [THIS VERSION IS STILL NOT OFFICIAL - JUST 2.3.2 SUPPLEMENT] This next version will bring Backup features as HGNB libraries are really important and a bug pre-2.3.2 literally destroyed tons of data. Backing up will be really simple and automatic.
 - (Version 2.4) This version makes case-sensitive an option.
 - (Version 2.4) categoryForPhrase is a cleaner way to use [probabilitiesForPhrase firstObject]. It does the same thing.
 
 --------------------------------------------------------------------------------------------------------------------------------

*/

#import <Foundation/Foundation.h>
#import <math.h>
#import "HGCloudManager.h"

@interface HGVersion : NSObject

@property  NSInteger major;
@property  NSInteger minor;
@property  NSInteger revision;

@end

@interface HGNaiveBayes : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentWebPage;
    NSMutableDictionary *listOfCategories, *listOfWords;
}

@property NSInteger numberOfTags, numberOfLearnedPhrases;
@property NSString *xmlTag, *xmlCategory;

//Runtime

/**
 Creates a clean HGNaiveBayes instance.
 @return The initialized classifier
 */
- (instancetype)init;
/**
 Returns the shared instance of the HGNaiveBayes class.
 @return The shared instance of the HGNaiveBayes class.
 */
+ (instancetype)sharedManager;
/**
 Creates a HGNaiveBayes instance by adding the downloaded XML data.
 @param url The XML URL.
 @param category The category of the content from the XML.
 @return The initialized classifier with the XML content.
 */
- (instancetype)initAndDownloadXML:(NSURL*)url categoryOfXML:(NSString *)category;

- (instancetype)initWithOtherLibrary:(NSDictionary*)library;

//Train + Learning
/**
 Downloads phrases from a XML and adds to the library.
 @param url The XML URL.
 @param category The category of the content from the XML.
 */
- (void)downloadDatabaseFromURL:(NSURL*)url categoryOfXML:(NSString *)category; //This may be slow  (needs to be called from ViewController)
/**
 Trains the library with a single phrase.
 @param phrase The phrase to be added.
 @param category The category of the phrase.
 @param forced YES if the user forced the phrase to be on the specified category.
 */
- (void)trainDatabaseWithPhrase:(NSArray*)phrase andCategory:(NSString*)category forced:(BOOL)isForced;
/**
 Trains the library with multiple phrases.
 @param phrases The phrases to be added.
 @param category The category of the phrases.
 */
- (void)trainDatabaseWithPhrases:(NSArray*)phrases withCategories:(NSArray*)categories;
/**
 Trains the library with a single phrase. Both arrays MUST have the same length for index checking.
 @param phrase The phrase to be added.
 @param category The category of the phrase.
 */
- (void)trainDatabaseManually:(NSArray*)phrase newCategory:(NSString*)category;

/**
 Receives the phrase string and returns an array organizing words by index.
 @param phrase The NSString phrase.
 @return NSArray containing all worrds.
 */
- (NSArray *)wordsOfPhrase:(NSString *)phrase;

//Classifying
/**
 Classifies the phrase.
 @param phrase The phrase to be classified.
 @return The category of the phrase.
 */

- (NSString *)classifyPhrase:(NSArray*)phrase __unavailable	__attribute__((unavailable));

//Classifying
/**
 Classifies the phrase.
 @param phrase The phrase to be classified
 @return An array containing the probabilities for each category. The first item is the best category.
 */
- (NSArray *)probabilitiesForPhrase:(NSArray*)phrase;


/**
 Returns a new array containing the session categories.
 The order of the elements in the array is not defined.
 @return A new array containig the categories, or an empty array if there's no categories.
 */
- (NSArray*)allCategories;

/**
 Returns a integer containing the word count.
 @param word The word to find.
 @return The number of times the word has been classified, or zero if the word is not on the list.
 */
- (NSInteger)countForWord:(NSString*)word;

/**
 Remove all words and the category.
 @param category The category to remove.
 @param numOfPhrases Category number of phrases.
 @return TRUE if the library was saved or FALSE if it failed.
 */
- (BOOL)removeCategory:(NSString*)category numOfPhrases:(NSInteger)numOfPhrases;

/**
 Remove a category from the words.
 @param words The words you want to remove.
 @param category The category you want to remove from the words.
 @return TRUE if the library was saved or FALSE if it failed.
 */
- (BOOL)removeWords:(NSArray*)words from:(NSString *)category;

/**
 Returns all words from the category.
 @param category The category you want to look for words.
 @return All words from the category.
 */
- (NSArray*)wordsInCategory:(NSString*)category;

- (HGVersion*)naiveLibraryVersion;

- (HGVersion*)libraryVersion;

- (HGVersion*)naiveVersion;

- (void)printSession;

- (NSURL*)libraryAddress;

@end
