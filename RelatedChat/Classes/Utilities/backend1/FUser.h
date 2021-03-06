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

#import "FObject.h"

NS_ASSUME_NONNULL_BEGIN

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface FUser : FObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Class methods

+ (NSString *)currentId;

+ (FUser *)currentUser;

+ (instancetype)userWithId:(NSString *)uid;

+ (void)signInWithEmail:(NSString *)email password:(NSString *)password
			 completion:(void (^)(FUser *user, NSError *error))completion;

+ (void)createUserWithEmail:(NSString *)email password:(NSString *)password
				 completion:(void (^)(FUser *user, NSError *error))completion;

+ (void)signInWithCredential:(FIRAuthCredential *)credential
				  completion:(void (^)(FUser *user, NSError *error))completion;

+ (BOOL)logOut;

#pragma mark - Instance methods

- (BOOL)isCurrent;

@end

NS_ASSUME_NONNULL_END

