/*
 * TNToolbarLogs.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "TNCellLogLevel.j";

TNLogLevelFatal = @"fatal";
TNLogLevelError = @"error";
TNLogLevelWarn  = @"warn";
TNLogLevelInfo  = @"info";
TNLogLevelDebug = @"debug";
TNLogLevelTrace = @"trace";

TNLogLevels     = [TNLogLevelTrace, TNLogLevelDebug, TNLogLevelInfo, TNLogLevelWarn, TNLogLevelError, TNLogLevelFatal];

// var TNLog = function (aMessage, aLevel, aTitle) {
//     [theSharedLogger logMessage:aMessage title:aTitle level:aLevel];
// }
// 
// var theSharedLogger;



/*! @ingroup archipelcore
    provides a logging facility. Logs are store using HTML5 storage.
*/
@implementation TNToolbarLogs: TNModule
{
    @outlet CPScrollView    mainScrollView;
    @outlet CPPopUpButton   buttonLogLevel;
    
    CPArray         _logs;
    CPTableView     _tableViewLogging;
    id              _logFunction;
}

/*! get the shared logger
    @return the shared logger
*/

// + (id)sharedLogger
// {
//     return theSharedLogger;
// }


- (void)willLoad
{
    [super willLoad];
    // message sent when view will be added from superview;
}

- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

- (void)willShow
{
    [super willShow];
    // message sent when the tab is clicked
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

/*! init the class with a rect
    @param aFrame a CPRect containing the frame information
*/
- (void)awakeFromCib
{
    _logFunction = function (aMessage, aLevel, aTitle) {
        [self logMessage:aMessage title:aTitle level:aLevel];
    };
    
    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"];
    [mainScrollView setAutohidesScrollers:YES];
    
    var defaults = [TNUserDefaults standardUserDefaults];
    maxLogLevel = [defaults objectForKey:@"TNArchipelLogStoredMaximumLevel"];
    
    if (!maxLogLevel)
        maxLogLevel = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TNDefaultLogLevel"];
    
    CPLogRegister(_logFunction, maxLogLevel);
    CPLogRegister(CPLogConsole, maxLogLevel);
    
    _logs = [self restaure];

    _tableViewLogging = [[CPTableView alloc] initWithFrame:[[mainScrollView contentView] frame]];

    [_tableViewLogging setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableViewLogging setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewLogging setAllowsColumnResizing:YES];
    [_tableViewLogging setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    
    var columnMessage = [[CPTableColumn alloc] initWithIdentifier:@"message"];
    [[columnMessage headerView] setStringValue:@"Message"];

    var columnDate = [[CPTableColumn alloc] initWithIdentifier:@"date"];
    [columnDate setWidth:130];
    [[columnDate headerView] setStringValue:@"Date"];
    
    var columnTitle = [[CPTableColumn alloc] initWithIdentifier:@"title"];
    [[columnTitle headerView] setStringValue:@"Title"];
    
    var levelCellPrototype = [[TNCellLogLevel alloc] init];
    var columnLevel = [[CPTableColumn alloc] initWithIdentifier:@"level"];
    [columnLevel setWidth:50];
    [columnLevel setDataView:levelCellPrototype];
    [[columnLevel headerView] setStringValue:@"Level"];
    
    [_tableViewLogging addTableColumn:columnLevel];
    [_tableViewLogging addTableColumn:columnDate];
    // [_tableViewLogging addTableColumn:columnTitle];
    [_tableViewLogging addTableColumn:columnMessage];

    [_tableViewLogging setDataSource:self];

    [mainScrollView setDocumentView:_tableViewLogging];
    
    [buttonLogLevel removeAllItems];
    for (var i = 0; i < [TNLogLevels count]; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:[TNLogLevels objectAtIndex:i] action:nil keyEquivalent:nil];
        [buttonLogLevel addItem:item];
    }
    [buttonLogLevel selectItemWithTitle:maxLogLevel];
    
    theSharedLogger = self;
}

- (void)save
{
    // var defaults = [TNUserDefaults standardUserDefaults];
    // [defaults setObject:_logs forKey:@"storedLogs"];    
    // ?????
    
    localStorage.setItem("storedLogs", JSON.stringify(_logs));

}

- (CPArray)restaure
{
    // var defaults        = [TNUserDefaults standardUserDefaults];
    // var recoveredLogs   = [defaults objectForKey:@"storedLogs"];
    // ?????
    
    var recoveredLogs = JSON.parse(localStorage.getItem("storedLogs"));
    
    return (recoveredLogs) ? recoveredLogs : [CPArray array];
}

/*! write log to the logger
    @param aString CPString containing the log message
*/
- (void)logMessage:(CPString)aMessage title:(CPString)aTitle level:(CPString)aLevel
{
    var theDate     = [CPDate dateWithFormat:@"Y/m/d H:i:s"];
    var logEntry    = {"date": theDate, "message": aMessage, "title": aTitle, "level": aLevel};
    
    [_logs insertObject:logEntry atIndex:0];
    
    [_tableViewLogging reloadData];

    [self save];
}

/*! remove all previous stored logs
*/
- (IBAction)clearLog:(id)sender
{
    [_logs removeAllObjects];
    [_tableViewLogging reloadData];

    [self save];
}

- (IBAction)setLogLevel:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    var logLevel = [buttonLogLevel title];
    
    [defaults setObject:logLevel forKey:@"TNArchipelLogStoredMaximumLevel"];
    
    CPLogUnregister(_logFunction);
    CPLogUnregister(CPLogConsole);
    
    CPLogRegister(_logFunction, logLevel);
    CPLogRegister(CPLogConsole, logLevel);
    CPLog.info(@"Log level set to " + logLevel);
}

/*! CPTableView delegate
*/
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [_logs count]
}

/*! CPTableView delegate
*/
- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPTableColumn)aCol row:(CPNumber)aRow
{
    var anIdentifier    = [aCol identifier];
    var value           = _logs[aRow][anIdentifier];
    
    return value;
}

@end


