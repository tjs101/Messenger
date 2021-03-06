//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GroupView.h"
#import "SelectMultipleView.h"
#import "AllMediaView.h"
#import "ProfileView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface GroupView()
{
	FObject *group;
	DBGroup *dbgroup;
	NSMutableArray *dbusers;
}

@property (strong, nonatomic) IBOutlet UITableViewCell *cellDetails;
@property (strong, nonatomic) IBOutlet UIImageView *imageGroup;
@property (strong, nonatomic) IBOutlet UILabel *labelName;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellMedia;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellLeave;

@property (strong, nonatomic) IBOutlet UIView *viewFooter;
@property (strong, nonatomic) IBOutlet UILabel *labelFooter1;
@property (strong, nonatomic) IBOutlet UILabel *labelFooter2;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation GroupView

@synthesize cellDetails, imageGroup, labelName;
@synthesize cellMedia, cellLeave;
@synthesize viewFooter, labelFooter1, labelFooter2;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)groupId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", groupId];
	dbgroup = [[DBGroup objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Group";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"group_more"]
																	  style:UIBarButtonItemStylePlain target:self action:@selector(actionMore)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = viewFooter;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbusers = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self fetchGroup];
	[self loadGroup];
	[self loadUsers];
}

#pragma mark - Backend actions (load)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)fetchGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *object = [FObject objectWithPath:FGROUP_PATH];
	object[FGROUP_OBJECTID] = dbgroup.objectId;
	[object fetchInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			group = object;
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:dbgroup.picture completion:^(NSString *path, NSError *error, BOOL network)
	{
		if (error == nil) imageGroup.image = [[UIImage alloc] initWithContentsOfFile:path];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelName.text = dbgroup.name;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", dbgroup.userId];
	DBUser *dbuser = [[DBUser objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelFooter1.text = [NSString stringWithFormat:@"Created by %@", dbuser.fullname];
	labelFooter2.text = Date2MediumTime([NSDate dateWithTimestamp:dbgroup.createdAt]);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUsers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[dbusers removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *members = [dbgroup.members componentsSeparatedByString:@","];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBUser *dbuser in [[DBUser allObjects] sortedResultsUsingProperty:FUSER_FULLNAME ascending:YES])
	{
		if ([members containsObject:dbuser.objectId])
			[dbusers addObject:dbuser];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

#pragma mark - Backend actions (save)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)saveGroupName:(NSString *)name
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (group == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	group[FGROUP_NAME] = name;
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			labelName.text = name;
			[Recent updateDescription:group];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)saveGroupPicture:(NSString *)linkPicture
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (group == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	group[FGROUP_PICTURE] = linkPicture;
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[Recent updatePicture:group];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - Backend actions (members)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)addGroupMembers:(NSArray *)userIds
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (group == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (NSString *userId in userIds)
	{
		if ([group[FGROUP_MEMBERS] containsObject:userId] == NO)
			[group[FGROUP_MEMBERS] addObject:userId];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[self loadUsers];
			[Chat startGroup1:group];
			[Recent updateMembers:group];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delGroupMember:(DBUser *)dbuser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (group == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group[FGROUP_MEMBERS] removeObject:dbuser.objectId];
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[Recent updateMembers:group];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)leaveGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (group == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group[FGROUP_MEMBERS] removeObject:[FUser currentId]];
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[ProgressHUD dismiss];
			[Recent updateMembers:group];
			[self.navigationController popToRootViewControllerAnimated:YES];
			[NotificationCenter post:NOTIFICATION_CLEANUP_CHATVIEW];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - Backend actions (delete)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[Group deleteItem:dbgroup.objectId];
	[self.navigationController popToRootViewControllerAnimated:YES];
	[NotificationCenter post:NOTIFICATION_CLEANUP_CHATVIEW];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMore
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self isGroupOwner]) [self actionMoreOwner]; else [self actionMoreMember];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMoreOwner
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Add Members" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionAddMembers]; }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Rename Group" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionRenameGroup]; }];
	UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Change Picture" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionChangePicture]; }];
	UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"Delete Group" style:UIAlertActionStyleDestructive
													handler:^(UIAlertAction *action) { [self deleteGroup]; }];
	UIAlertAction *action5 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2]; [alert addAction:action3]; [alert addAction:action4]; [alert addAction:action5];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMoreMember
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Leave Group" style:UIAlertActionStyleDestructive
													handler:^(UIAlertAction *action) { [self leaveGroup]; }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAddMembers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectMultipleView *selectMultipleView = [[SelectMultipleView alloc] init];
	selectMultipleView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionRenameGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename Group" message:@"Enter a new name for this Group"
															preferredStyle:UIAlertControllerStyleAlert];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.text = dbgroup.name;
		textField.placeholder = @"Name";
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
	{
		UITextField *textField = alert.textFields[0];
		NSString *name = textField.text;
		if ([name length] != 0)
		{
			[self saveGroupName:name];
		}
		else [ProgressHUD showError:@"Group name must be specified."];
	}]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChangePicture
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Open Camera" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { PresentPhotoCamera(self, YES); }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { PresentPhotoLibrary(self, YES); }];
	UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2]; [alert addAction:action3];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMedia
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AllMediaView *allMediaView = [[AllMediaView alloc] initWith:group.objectId];
	[self.navigationController pushViewController:allMediaView animated:YES];
}

#pragma mark - SelectMultipleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectMultipleUsers:(NSArray *)userIds
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self addGroupMembers:userIds];
}

#pragma mark - UIImagePickerControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIImage *image = info[UIImagePickerControllerEditedImage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIImage *imagePicture = [Image square:image size:80];
	NSData *dataPicture = UIImageJPEGRepresentation(imagePicture, 0.6);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"group", @"jpg")];
	FIRStorageUploadTask *task = [reference putData:dataPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			imageGroup.image = imagePicture;
			[self saveGroupPicture:metadata.downloadURL.absoluteString];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 4;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return 1;
	if (section == 1) return 1;
	if (section == 2) return [dbusers count];
	if (section == 3) return [self isGroupOwner] ? 0 : 1;
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return nil;
	if (section == 1) return nil;
	if (section == 2) return [self titleForHeaderMembers];
	if (section == 3) return nil;
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ((indexPath.section == 0) && (indexPath.row == 0)) return cellDetails;
	if ((indexPath.section == 1) && (indexPath.row == 0)) return cellMedia;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 2)
	{
		return [self tableView:tableView cellForRowAtIndexPath2:indexPath];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((indexPath.section == 3) && (indexPath.row == 0)) return cellLeave;
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath2:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBUser *dbuser = dbusers[indexPath.row];
	cell.textLabel.text = dbuser.fullname;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.section == 2)
	{
		if ([self isGroupOwner])
		{
			DBUser *dbuser = dbusers[indexPath.row];
			return ([dbuser.objectId isEqualToString:[FUser currentId]] == NO);
		}
	}
	return NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBUser *dbuser = dbusers[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[dbusers removeObject:dbuser];
	[self delGroupMember:dbuser];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView headerViewForSection:2].textLabel.text = [self titleForHeaderMembers];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((indexPath.section == 1) && (indexPath.row == 0)) [self actionMedia];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 2)
	{
		DBUser *dbuser = dbusers[indexPath.row];
		if ([dbuser.objectId isEqualToString:[FUser currentId]] == NO)
		{
			ProfileView *profileView = [[ProfileView alloc] initWith:dbuser.objectId Chat:YES];
			[self.navigationController pushViewController:profileView animated:YES];
		}
		else [ProgressHUD showSuccess:@"This is you."];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((indexPath.section == 3) && (indexPath.row == 0)) [self actionMoreMember];
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)titleForHeaderMembers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = ([dbusers count] > 1) ? @"MEMBERS" : @"MEMBER";
	return [NSString stringWithFormat:@"%ld %@", (long) [dbusers count], text];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)isGroupOwner
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [dbgroup.userId isEqualToString:[FUser currentId]];
}

@end

