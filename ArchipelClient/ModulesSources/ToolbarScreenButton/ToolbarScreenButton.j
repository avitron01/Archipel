/*
 * TNSampleToolbarModule.j
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

@import "../../Model/TNModule.j"

@global TNArchipelEntityTypeVirtualMachine


/*! @defgroup  toolbardestroybutton Module Toolbar Button Destroy
    @desc This module displays a toolbar item that can send destroy action to the current entity
*/

var TNArchipelVNCInformationRecoveredNotification = @"TNArchipelVNCInformationRecoveredNotification",
    TNArchipelVNCShowExternalWindowNotification = @"TNArchipelVNCShowExternalWindowNotification";

/*! @ingroup toolbardestroybutton
    The module main controller
*/
@implementation TNToolbarScreenButtonController : TNModule
{
    BOOL    _vncReady;

}
#pragma mark -
#pragma mark Intialization

- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [[self UIItem] setEnabled:NO];

    return YES;
}


#pragma mark -
#pragma mark Notification handlers

- (void)setGUIAccordingToStatus:(CPNotification)aNotification
{
    if (!_vncReady)
    {
        [[self UIItem] setEnabled:NO];
        [_UIObject reloadToolbarItems];
        return;
    }

    switch ([_entity XMPPShow])
    {
        case TNStropheContactStatusOnline:
            [[self UIItem] setEnabled:YES];
            break;
        default:
            [[self UIItem] setEnabled:NO];
    }

    [_UIObject reloadToolbarItems];
}

- (void)didVNCInformationRecovered:(CPNotification)aNotification
{
    if (![[aNotification object] valueForAttribute:@"host"])
        _vncReady = NO;
    else
        _vncReady = YES;

    [self setGUIAccordingToStatus:nil];
}


#pragma mark -
#pragma mark Overrides

- (void)setEntity:(TNStropheContact)anEntity
{
    _vncReady = NO;
    [super setEntity:anEntity];

    [[CPNotificationCenter defaultCenter] removeObserver:self];

    if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[anEntity vCard]] !== TNArchipelEntityTypeVirtualMachine)
    {
        [[self UIItem] setEnabled:NO];
        [_UIObject reloadToolbarItems];
        return;
    }

    [self setGUIAccordingToStatus:nil];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didVNCInformationRecovered:) name:TNArchipelVNCInformationRecoveredNotification object:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(setGUIAccordingToStatus:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
}


#pragma mark -
#pragma mark Actions

/*! send TNArchipelControlNotification containing command TNArchipelControlDestroy
    to a loaded VirtualMachineControl module instance
*/
- (IBAction)toolbarItemClicked:(id)aSender
{
    var center = [CPNotificationCenter defaultCenter];

    CPLog.info(@"Sending TNArchipelVNCScreenNotification");
    [center postNotificationName:TNArchipelVNCShowExternalWindowNotification object:self userInfo:nil];
}

@end
