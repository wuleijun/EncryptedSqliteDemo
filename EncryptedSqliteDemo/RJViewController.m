//
//  RJViewController.m
//  EncryptedSqliteDemo
//
//  Created by jun on 14-6-6.
//  Copyright (c) 2014年 rayjune Wu. All rights reserved.
//

#define KSecretKey @"password"

#import "RJViewController.h"
#import <sqlite3.h>
#import "FMDatabase.h"

@interface RJViewController ()

@end

@implementation RJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)encryptDatabase_Touch:(id)sender {
    
    // Set the new encrypted database path to be in the Documents Folder
    NSString *ecDB = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                      stringByAppendingPathComponent: @"encrypted.sqlite"];
    
    NSString *unEncryDatabasePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                     stringByAppendingPathComponent: @"unencrypted.sqlite"];
    
    // SQL Query. NOTE THAT DATABASE IS THE FULL PATH NOT ONLY THE NAME
    const char* sqlQ = [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",ecDB,KSecretKey] UTF8String];
    
    sqlite3 *unencrypted_DB;
    if (sqlite3_open([unEncryDatabasePath UTF8String], &unencrypted_DB) == SQLITE_OK) {
        
        // Attach empty encrypted database to unencrypted database
        sqlite3_exec(unencrypted_DB, sqlQ, NULL, NULL, NULL);
        
        // export database
        sqlite3_exec(unencrypted_DB, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL);
        
        // Detach encrypted database
        if (sqlite3_exec(unencrypted_DB, "DETACH DATABASE encrypted;", NULL, NULL, NULL) == SQLITE_OK){
            
            //复制成功就删除原来的数据库
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            [fileManager removeItemAtPath:unEncryDatabasePath error:&error];
        };
        sqlite3_close(unencrypted_DB);
    }
    else {
        sqlite3_close(unencrypted_DB);
        NSAssert1(NO, @"Failed to open database with message '%s'.", sqlite3_errmsg(unencrypted_DB));
    }
    
    //操作加密的数据库
    FMDatabase *db = [FMDatabase databaseWithPath:[self getEncryptedDataBasePath]];
    [db open];
    [db setKey:KSecretKey];
    BOOL update = [db executeUpdate:[NSString stringWithFormat:@"create table MyTable (_id INTEGER PRIMARY KEY,FSCode varchar,FByIndex integer,FByName varchar,FFieldName varchar,FIsShowList integer,FDefault1 varchar,FDefault2 integer)"]];
    NSLog(@"%@",[db lastErrorMessage]);
    [db close];
    
}
- (IBAction)uncryptDatabase:(id)sender {
    NSString *unEncryDatabasePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                     stringByAppendingPathComponent: @"unencrypted.sqlite"];
    sqlite3 *encrypted_DB;
    if (sqlite3_open([[self getEncryptedDataBasePath] UTF8String], &encrypted_DB) == SQLITE_OK) {
        const char* key = [KSecretKey UTF8String];
        sqlite3_key(encrypted_DB, key, strlen(key));
        
        const char*attchSQL = [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS plaintext KEY ''",unEncryDatabasePath] UTF8String];
        sqlite3_exec(encrypted_DB, attchSQL, NULL, NULL, NULL);
        sqlite3_exec(encrypted_DB, "SELECT sqlcipher_export('plaintext')", NULL, NULL, NULL);
        

        if (sqlite3_exec(encrypted_DB, "DETACH DATABASE plaintext", NULL, NULL, NULL) == SQLITE_OK){
            
            //复制成功就删除原来的数据库
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            [fileManager removeItemAtPath:[self getEncryptedDataBasePath] error:&error];
        };
        NSLog(@"%d",sqlite3_exec(encrypted_DB, "DETACH DATABASE plaintext", NULL, NULL, NULL));
        sqlite3_close(encrypted_DB);
    }
    else {
        sqlite3_close(encrypted_DB);
        NSAssert1(NO, @"Failed to open database with message '%s'.", sqlite3_errmsg(encrypted_DB));
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getEncryptedDataBasePath
{
    return  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                      stringByAppendingPathComponent: @"encrypted.sqlite"];
}

@end
