// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get languageChoiceTitle => 'Choose language';

  @override
  String get languageHebrew => 'Hebrew';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountConflictTitle => 'We found an existing account for you';

  @override
  String get accountConflictMessage =>
      'This account already has saved progress from another device. Which progress would you like to use?';

  @override
  String get accountConflictCloudProgressTitle =>
      'Progress saved on the account';

  @override
  String get accountConflictLocalProgressTitle =>
      'Current progress on this device';

  @override
  String get accountConflictUseCloudButton => 'Continue with saved progress';

  @override
  String get accountConflictUseLocalButton => 'Keep my current progress';

  @override
  String get accountConflictWarning =>
      'Note: the option you don\'t choose will be deleted and cannot be recovered.';

  @override
  String get accountConflictCancelButton => 'Cancel';

  @override
  String accountConflictLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get accountLinkTitle => 'Save your progress';

  @override
  String get accountLinkMessage =>
      'Link a Google or Apple account - that way, if you switch phones, all your coins and progress will be saved and waiting for you.';

  @override
  String get accountLinkCancelButton => 'Cancel';

  @override
  String get accountLinkContinueWithGoogle => 'Continue with Google';

  @override
  String get accountLinkContinueWithApple => 'Continue with Apple';

  @override
  String get accountLinkLaterButton => 'Later';

  @override
  String get accountLinkDontShowAgain => 'Don\'t show this again';

  @override
  String get accountLinkSuccessMessage =>
      'Account linked successfully! Your progress is saved';

  @override
  String get accountLinkFailedMessage =>
      'Sign-in failed, please try again later';

  @override
  String get notEnoughCoinsTitle => 'You don\'t have enough coins';

  @override
  String notEnoughCoinsMessage(int cost, int coins) {
    return 'This costs $cost coins and you only have $coins';
  }

  @override
  String notEnoughCoinsMissing(int amount) {
    return '$amount missing';
  }

  @override
  String get notEnoughCoinsShopButton => 'Go to the coin shop';

  @override
  String get notEnoughCoinsCancelButton => 'Cancel';

  @override
  String get onboardingGiftHeader => 'You finished the tutorial';

  @override
  String get onboardingGiftTitle => 'Reward collected!';

  @override
  String get onboardingGiftSubtitle =>
      'You earned this for the first level - you\'re ready to continue on your own!';

  @override
  String onboardingGiftRewardCoinsEnergy(int coins, int energy) {
    return '$coins coins + $energy energy';
  }

  @override
  String onboardingGiftRewardCoinsOnly(int coins) {
    return '$coins coins';
  }

  @override
  String get onboardingGiftRewardLabel => 'Tutorial completion gift';

  @override
  String get onboardingGiftContinueButton => 'Keep playing ›';

  @override
  String outOfResourceTimeHours(String time) {
    return '$time hours';
  }

  @override
  String outOfResourceTimeMinutes(String time) {
    return '$time minutes';
  }

  @override
  String outOfResourceAdCoinsCooldownMsg(String time) {
    return 'You can get coins from an ad again in $time';
  }

  @override
  String get outOfResourceNoAdAvailable =>
      'No ad available right now, try again in a moment';

  @override
  String outOfResourceAdEnergyCooldownMsg(String time) {
    return 'You can watch another ad in $time';
  }

  @override
  String outOfResourceCoinsRewardSubtitle(int hours) {
    return 'Comes back again in $hours hours';
  }

  @override
  String outOfResourceWatchAdCoins(int amount) {
    return 'Watch an ad (+$amount coins) 🎬';
  }

  @override
  String outOfResourceWatchAdEnergy(int amount) {
    return 'Watch an ad (+$amount energy) 🎬';
  }

  @override
  String get outOfResourceBuyCoinsButton => 'Buy coins in the shop 🪙';

  @override
  String get outOfResourceBuyEnergyButton => 'Buy energy in the shop ⚡';

  @override
  String get explainerGotItButton => 'Got it!';

  @override
  String get duelLobbyBarTitleSearching => 'Looking for an opponent';

  @override
  String duelLobbyBarSubtitleSearching(int stake, int logos) {
    return 'Duel for $stake coins · $logos logos';
  }

  @override
  String get duelLobbyBarTitleDefault => '1v1 Duel';

  @override
  String get duelLobbyBarSubtitleChoosing => 'Choose what you\'re playing for';

  @override
  String get duelLobbyBannedTitle => 'Temporarily banned from duels';

  @override
  String duelLobbyBannedMessage(String time) {
    return 'You left a duel in the middle more than once - that\'s not fair to opponents waiting for an answer. You can play a duel again in $time.';
  }

  @override
  String get duelLobbyBannedTimeFewMoments => 'a few moments';

  @override
  String duelLobbyBannedTimeHoursMinutes(int hours, int minutes) {
    return '$hours hours and $minutes minutes';
  }

  @override
  String duelLobbyBannedTimeMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get duelLobbyBackButton => 'Back';

  @override
  String get duelLobbyClearBanDebugButton => 'Clear ban (debug)';

  @override
  String get duelLobbyStakeSheetTitle => 'What are you playing for?';

  @override
  String duelLobbyEnergyInfoRow(int cost, int energy) {
    return 'Every duel costs $cost energy · you have $energy';
  }

  @override
  String get duelLobbyCancelButton => 'Cancel';

  @override
  String duelLobbyStakeSubtitle(int logos, int prize) {
    return '$logos logos · winner takes $prize';
  }

  @override
  String get duelLobbyMostPopularBadge => 'Most popular';

  @override
  String duelLobbyStakeCoinsLabel(int stake) {
    return '$stake coins';
  }

  @override
  String get duelLobbyBadgeBlitz => 'Blitz ⚡';

  @override
  String get duelLobbyBadgeWarmup => 'Warm-up';

  @override
  String get duelLobbyBadgeExperienced => 'Experienced';

  @override
  String get duelLobbyBadgeMax => 'Maximum';

  @override
  String get duelLobbyBadgePro => 'Pro';

  @override
  String get duelLobbyReadyLabel => 'Ready ✓';

  @override
  String get duelLobbySearchingLabel => 'Searching…';

  @override
  String get duelLobbyConnectingLabel => 'Connecting…';

  @override
  String duelLobbySearchingElapsed(String time) {
    return 'Looking for an opponent… $time';
  }

  @override
  String get duelLobbyConditionsTitle => 'Duel terms';

  @override
  String get duelLobbyStatStake => 'Stake';

  @override
  String get duelLobbyStatLogos => 'Logos';

  @override
  String get duelLobbyStatWinner => 'To winner';

  @override
  String get duelLobbyNotEnoughEnergyTitle => 'Out of energy ⚡';

  @override
  String duelLobbyNotEnoughEnergyMessage(int cost, int max, int minutes) {
    return 'Every duel costs $cost energy out of $max. Energy refills automatically every $minutes minutes.';
  }

  @override
  String duelLobbyWatchAdEnergyButton(int amount) {
    return 'Watch an ad (+$amount energy) 🎬';
  }

  @override
  String get duelLobbyBuyEnergyButton => 'Buy energy in the shop ⚡';

  @override
  String get duelLobbyNotEnoughCoinsTitle => 'Not enough coins';

  @override
  String duelLobbyNotEnoughCoinsMessage(int stake, int coins) {
    return 'Duel entry fee: starting from $stake coins (you have $coins). The winner takes the whole pot!';
  }

  @override
  String get duelLobbyFoundTitleFallback => 'Opponent found! ⚔️';

  @override
  String get duelLobbyOpponentFallbackName => 'opponent';

  @override
  String get duelLobbyOpponentFallbackNameWithThe => 'The opponent';

  @override
  String get duelLobbyFoundBadge => 'Opponent found!';

  @override
  String get duelLobbyYouLabel => 'You';

  @override
  String get duelLobbyOpponentLabel => 'Opponent';

  @override
  String get duelLobbyStartingIn => 'Duel starts in';

  @override
  String get duelLobbyCancelDuelButton => 'Cancel duel';

  @override
  String get duelLobbyRankLabel => 'Rank';

  @override
  String get duelLobbyWinsLabel => 'Wins';

  @override
  String get duelLobbyH2hTitle => 'Head to head record';

  @override
  String duelLobbyH2hYouWins(int wins) {
    return 'You $wins wins';
  }

  @override
  String duelLobbyH2hOpponentScore(String name, int wins) {
    return '$name $wins';
  }

  @override
  String get duelLobbyNoPlayersTitle => 'No players online right now 🙁';

  @override
  String get duelLobbyNoPlayersMessage =>
      'Try again in a few minutes, or invite friends to play together';

  @override
  String get duelLobbyRetryButton => 'Try again';

  @override
  String get duelLobbyErrorTitle => 'Something went wrong';

  @override
  String get duelLobbyStakeErrorMessage =>
      'Something went wrong, your energy was refunded. Try again.';

  @override
  String duelLobbyAdCooldownMsg(String time) {
    return 'You can watch another ad in $time';
  }

  @override
  String get duelLobbyNoAdAvailable =>
      'No ad available right now, try again in a moment';

  @override
  String get duelLobbyOpponentCancelledMessage =>
      'The opponent cancelled the duel before it started';

  @override
  String get duelLobbySearchingTip1 =>
      'Tip: everyone answers at their own pace - whoever finishes 10 logos first wins';

  @override
  String get duelLobbySearchingTip2 =>
      'Tip: you can buy a cheap hint inside the duel if you get stuck';

  @override
  String get duelLobbySearchingTip3 =>
      'Tip: the winner takes the whole coin pot from both players';

  @override
  String get duelLobbySearchingTip4 =>
      'Tip: your opponent doesn\'t have good internet? They\'ll rejoin the queue in a second';

  @override
  String get duelLobbySearchingTip5 =>
      'Tip: practice in regular mode to learn more logos before a duel';

  @override
  String get logoRaceSearchingTip1 =>
      'Tip: the logo starts almost fully covered - the more the circle opens, the easier it is to guess';

  @override
  String get logoRaceSearchingTip2 =>
      'Tip: whoever types the full correct answer first wins the round';

  @override
  String get logoRaceSearchingTip3 =>
      'Tip: you can see the opponent\'s wrong guesses in the chat in real time too';

  @override
  String get logoRaceSearchingTip4 =>
      'Tip: the winner takes the whole coin pot from both players';

  @override
  String get logoRaceSearchingTip5 =>
      'Tip: the higher the stake level, the more logos there are in the race';

  @override
  String get logoRaceNotEnoughEnergyTitle => 'Not enough energy';

  @override
  String logoRaceNotEnoughEnergyMessage(int cost, int max, int minutes) {
    return 'A race requires $cost energy out of $max. Energy refills automatically every $minutes minutes.';
  }

  @override
  String logoRaceNotEnoughCoinsMessage(int stake, int coins) {
    return 'Race entry fee: starting from $stake coins (you have $coins). The winner takes the whole pot!';
  }

  @override
  String get logoRaceConnectErrorTitle => 'We couldn\'t connect';

  @override
  String get logoRaceConnectErrorMessage =>
      'Check your internet connection and try again';

  @override
  String get logoRaceNoOpponentTitle => 'No opponent available right now';

  @override
  String get logoRaceNoOpponentMessage =>
      'Your energy was refunded - try again in a moment';

  @override
  String logoRaceWaitingReconnect(String name) {
    return 'Waiting for $name to reconnect';
  }

  @override
  String logoRaceReconnectTimeoutWarning(int seconds) {
    return 'If they don\'t reconnect within $seconds seconds, it will count as a technical win';
  }

  @override
  String get logoRaceDecidingTechnicalWin => 'Deciding technical win…';

  @override
  String logoRaceBarSubtitleSearching(int stake, int logos) {
    return 'Race for $stake coins · $logos logos';
  }

  @override
  String get logoRaceBarTitleDefault => 'Logo Race 🏁';

  @override
  String get logoRaceBarTitleResults => 'Race results 🏁';

  @override
  String get logoRaceStakeSheetSubtitle =>
      'The stake is taken from both players';

  @override
  String get logoRaceInfoRow =>
      'Each logo is almost fully hidden - whoever guesses correctly first in the chat wins the round.';

  @override
  String get logoRacePlayButton => 'Play';

  @override
  String get logoRaceConditionsTitle => 'Race terms';

  @override
  String get logoRaceStartingIn => 'Race starts in';

  @override
  String logoRaceYouScoreLabel(int score) {
    return 'You: $score';
  }

  @override
  String logoRaceLogoCounter(int current, int total) {
    return 'Logo $current/$total';
  }

  @override
  String logoRaceOpponentScoreLabel(String name, int score) {
    return '$name: $score';
  }

  @override
  String get logoRaceRoundNoneGuessed => 'Time\'s up - nobody guessed';

  @override
  String get logoRaceRoundYouWon =>
      'You guessed right! Moving to the next logo...';

  @override
  String logoRaceRoundOpponentWon(String name) {
    return '$name guessed right! Moving to the next logo...';
  }

  @override
  String get logoRaceRemoveLetterButton => 'Remove letter';

  @override
  String get logoRaceWinTitle => 'You won!';

  @override
  String get logoRaceDrawTitle => 'Draw!';

  @override
  String get logoRaceLossTitle => 'Opponent won';

  @override
  String logoRaceResultBadge(int stake) {
    return '🏁 Race · for $stake coins';
  }

  @override
  String logoRaceScoreSummary(int score, int total) {
    return '$score out of $total logos';
  }

  @override
  String get logoRacePrizeLabel => 'Your prize';

  @override
  String get logoRacePrizeCoinsLabel => 'Coins';

  @override
  String get logoRacePlayAgainButton => 'Another race 🏁';

  @override
  String get logoRaceShareButton => 'Share';

  @override
  String logoRaceShareTextWin(int score, int total) {
    return 'I won a logo race in \"Guess the Logo!\" 🏁 $score/$total logos. Come try to beat me! 🎮';
  }

  @override
  String get logoRaceShareTextLose =>
      'I played a logo race in \"Guess the Logo!\" - come challenge me! 🏁';

  @override
  String get logoRaceBackToMenuButton => 'Back to menu';

  @override
  String get logoRaceExitConfirmTitle => 'Leave the race?';

  @override
  String logoRaceExitConfirmMessage(int stake1, int stake2) {
    return 'If you leave now the opponent will be declared the winner and get the whole pot ($stake1 you staked + $stake2 theirs) - the coins you already paid won\'t be refunded.';
  }

  @override
  String get logoRaceExitEarlyWarning =>
      'This is an early departure - you\'ll only get a warning';

  @override
  String get logoRaceExitForfeitWarning =>
      'Leaving at this stage counts as forfeiting';

  @override
  String logoRaceExitBanThreshold(int count) {
    return '($count warnings = temporary ban).';
  }

  @override
  String get logoRaceStayButton => 'Stay';

  @override
  String get logoRaceLeaveAnywayButton => 'Leave anyway';

  @override
  String get logoRaceGoLabel => 'Go!';

  @override
  String duelRoomSeriesRoundBadge(int round) {
    return '🏆 Round $round/3 in the series';
  }

  @override
  String get duelRoomRoundWinTitle => 'You won the round!';

  @override
  String get duelRoomRoundDrawTitle => 'Round draw';

  @override
  String get duelRoomRoundLossTitle => 'Opponent won the round';

  @override
  String duelRoomSeriesScoreLine(int myWins, int oppWins, String oppName) {
    return 'Series: $myWins - $oppWins vs $oppName';
  }

  @override
  String get duelRoomMovingToNextRound => 'Moving to the next round...';

  @override
  String get duelRoomChooseHintTitle => 'Choose a hint';

  @override
  String get duelRoomRevealLetterTitle => 'Reveal a letter';

  @override
  String get duelRoomRevealLetterSubtitle =>
      'One more letter is revealed immediately';

  @override
  String get duelRoomSolveWordTitle => 'Solve the whole word';

  @override
  String get duelRoomSolveWordSubtitle => 'All letters are revealed at once';

  @override
  String get duelRoomHintsNotAvailable =>
      'Hints aren\'t available at this stake - only available from 100 coins and up';

  @override
  String duelRoomSeriesBadge(int stake) {
    return '🏆 Duel series · for $stake coins';
  }

  @override
  String duelRoomDuelBadge(int stake) {
    return '⚔️ Duel · for $stake coins';
  }

  @override
  String get duelRoomWinTitle => 'You won!';

  @override
  String get duelRoomDrawTitle => 'Draw!';

  @override
  String get duelRoomLossTitle => 'Opponent won';

  @override
  String duelRoomSeriesDrawScore(int myWins, int oppWins) {
    return 'Series draw · $myWins-$oppWins';
  }

  @override
  String duelRoomSeriesWinScore(int myWins, int oppWins) {
    return 'You won the series $myWins-$oppWins';
  }

  @override
  String duelRoomSeriesLossScore(int myWins, int oppWins) {
    return 'You lost the series $myWins-$oppWins';
  }

  @override
  String duelRoomScoreTimeSummary(int score, int total, String elapsed) {
    return '$score out of $total logos · $elapsed minutes';
  }

  @override
  String duelRoomWaitingForRematch(String name) {
    return 'Waiting for $name... ⏳';
  }

  @override
  String duelRoomRematchButton(String name) {
    return 'Play again vs $name 🔁';
  }

  @override
  String get duelRoomPlayAgainButton => 'Another duel ⚔️';

  @override
  String duelRoomShareTextWin(int score, int total, String elapsed) {
    return 'I won a duel in \"Guess the Logo!\" 🏆 $score/$total logos in $elapsed minutes. Come try to beat me! 🎮';
  }

  @override
  String get duelRoomShareTextLose =>
      'I played a duel in \"Guess the Logo!\" - come challenge me! ⚔️';

  @override
  String get duelRoomExitConfirmTitle => 'Leave the duel?';

  @override
  String duelRoomExitConfirmMessage(int stake1, int stake2) {
    return 'If you leave now the opponent will be declared the winner and get the whole pot ($stake1 you staked + $stake2 theirs) - the coins and energy you already paid won\'t be refunded.';
  }

  @override
  String duelRoomExitBanThreshold(int count) {
    return '($count warnings = temporary duel ban).';
  }

  @override
  String get duelRoomPreparingNextRound => 'Preparing the next round...';

  @override
  String get duelRoomOpponentFoundTitle => 'Opponent found!';

  @override
  String get duelRoomGoLabel => 'Go!';

  @override
  String duelRoomLogoCounter(int current, int total) {
    return 'Logo $current of $total';
  }

  @override
  String get duelRoomCorrectAnswerBanner => 'Correct answer!';

  @override
  String get duelRoomTimeUpBanner => 'Time\'s up!';

  @override
  String get duelRoomHintChipLabel => 'Hint';

  @override
  String duelRoomFinishedAllLogos(int total) {
    return 'You finished all $total logos! 🎉';
  }

  @override
  String duelRoomWaitingForOpponentToFinish(String name) {
    return 'Waiting for $name to finish too...';
  }

  @override
  String duelRoomHeaderBadge(int stake) {
    return 'Duel · for $stake coins';
  }

  @override
  String duelRoomOpponentAnsweredBanner(String name) {
    return '$name answered correctly!';
  }

  @override
  String duelRoomSeriesRoundHeader(int round, int myWins, int oppWins) {
    return 'Series · round $round/3 · $myWins-$oppWins';
  }

  @override
  String duelRoomYouLeadBy(String amount) {
    return 'You\'re leading by $amount';
  }

  @override
  String duelRoomOpponentLeadBy(String name, String amount) {
    return '$name is leading by $amount';
  }

  @override
  String get duelRoomCorrectAnswersSingular => 'one correct answer';

  @override
  String duelRoomCorrectAnswersPlural(int count) {
    return '$count correct answers';
  }

  @override
  String get duelSeasonLbTitle => 'Duel season leaderboard';

  @override
  String get duelSeasonLbEmptyTitle => 'No wins yet this month';

  @override
  String get duelSeasonLbEmptyMessage =>
      'Be the first to win a duel this month and open the board!';

  @override
  String get duelSeasonLbOthersSection => 'Other leaders';

  @override
  String get duelSeasonLbYourPlaceSection => 'Your place';

  @override
  String get duelSeasonLbPlayerFallbackName => 'Player';

  @override
  String duelSeasonLbYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get playVsPersonSeriesTitle => 'Duel series';

  @override
  String get playVsPersonSeriesSubtitle =>
      'Best of 3 vs the same opponent · coin bonus for winning the series';

  @override
  String get playVsPersonNewBadge => 'New';

  @override
  String get playVsPersonDuelTitle => 'Duel';

  @override
  String get playVsPersonDuelSubtitle => '1v1 · whoever solves more logos wins';

  @override
  String get playVsPersonRaceTitle => 'Race';

  @override
  String get playVsPersonRaceSubtitle =>
      '1v1 · whoever guesses each logo first wins';

  @override
  String playVsPersonLogosRangeSingle(int count) {
    return '$count logos';
  }

  @override
  String playVsPersonLogosRange(int min, int max) {
    return '$min–$max logos';
  }

  @override
  String get playVsPersonSeasonBoardButton => 'Season board';

  @override
  String get playVsPersonInviteFriendButton => 'Invite a friend';

  @override
  String get playVsPersonIntroTitle => '3 ways to play against others';

  @override
  String get playVsPersonSeriesIntroDesc =>
      'Best of 3 vs the same opponent - coin bonus for winning the series';

  @override
  String get playVsPersonDuelIntroTitle => 'Duel';

  @override
  String get playVsPersonDuelIntroDesc =>
      '1v1 showdown - whoever solves more logos wins';

  @override
  String get playVsPersonRaceIntroDesc =>
      '1v1 showdown - whoever guesses each logo first wins';

  @override
  String get playVsPersonIntroGotItButton => 'Got it, let\'s choose!';

  @override
  String get playVsPersonInviteDirectlyTitle => 'Invite a friend directly';

  @override
  String get playVsPersonFriendOffline => 'Offline';

  @override
  String get playVsPersonChooseModeTitle => 'Choose a mode';

  @override
  String playVsPersonConnectedCount(int count) {
    return '$count online';
  }

  @override
  String get playVsPersonPlayingLabel => 'playing';

  @override
  String get playVsPersonChooseButton => 'Choose';

  @override
  String get friendChallengeModeDuel => 'duel';

  @override
  String get friendChallengeModeRace => 'race';

  @override
  String get friendChallengeCreateInviteFailed =>
      'We couldn\'t create an invite code - try again';

  @override
  String get friendChallengeCodeCopied => 'Code copied! Send it to your friend';

  @override
  String friendChallengeShareText(String mode, String code) {
    return 'Let\'s play a $mode in \"Guess the Logo!\" 🔗 My code: $code';
  }

  @override
  String friendChallengeShareSubject(String mode) {
    return '$mode challenge';
  }

  @override
  String friendChallengeNoShareAppFallback(String text) {
    return 'No sharing app found. You can copy and send it manually:\n$text';
  }

  @override
  String friendChallengeCodeLengthError(int length) {
    return 'Code must be $length characters';
  }

  @override
  String get friendChallengeCodeNotFoundDetailed =>
      'No such code found - make sure you typed it correctly';

  @override
  String get friendChallengeOwnCodeDetailed =>
      'This is your own code - send it to a friend, don\'t enter it here';

  @override
  String get friendChallengeCodeAlreadyUsed =>
      'Someone already joined this code';

  @override
  String get friendChallengeCodeExpired => 'This code has already expired';

  @override
  String friendChallengeNotEnoughCoinsForStake(int stake) {
    return 'You don\'t have enough coins for this stake ($stake)';
  }

  @override
  String get friendChallengeCodeNotFound => 'No such code found';

  @override
  String get friendChallengeOwnCode => 'This is your own code';

  @override
  String get friendChallengeGenericError => 'Something went wrong - try again';

  @override
  String get friendChallengeWaitingTitle => 'Waiting for friend';

  @override
  String get friendChallengeJoinWithCodeTitle => 'Join with a code';

  @override
  String get friendChallengeDefaultTitle => 'Challenge a friend';

  @override
  String friendChallengeBannedMessage(String time) {
    return 'You left a duel in the middle more than once. You can play a duel again in $time.';
  }

  @override
  String friendChallengeNotEnoughEnergyMessage(
    String mode,
    int cost,
    int minutes,
  ) {
    return 'Every $mode costs $cost energy. Energy refills automatically every $minutes minutes.';
  }

  @override
  String friendChallengeNotEnoughCoinsMessage(int stake, String mode) {
    return 'You need at least $stake coins to start a $mode.';
  }

  @override
  String friendChallengeDirectInviteTitle(String friendName, String mode) {
    return 'Inviting $friendName to a $mode';
  }

  @override
  String friendChallengeGenericInviteTitle(String mode) {
    return 'Challenge a friend to a $mode';
  }

  @override
  String friendChallengeDirectInviteSubtitle(String friendName) {
    return 'Choose what to play for - $friendName will get an immediate invite.';
  }

  @override
  String get friendChallengeGenericInviteSubtitle =>
      'Choose what to play for, then create a code to send a friend - or enter a code you already got.';

  @override
  String get friendChallengeSendInviteButton => 'Send invite 🎟️';

  @override
  String get friendChallengeCreateCodeButton =>
      'Create a code for a friend 🎟️';

  @override
  String get friendChallengeOrDivider => 'or';

  @override
  String get friendChallengeHaveCodeQuestion => 'Have a code from a friend?';

  @override
  String get friendChallengeJoinWithCodeButton => 'Join with a code ⌨️';

  @override
  String get friendChallengeFriendFallback => 'friend';

  @override
  String get friendChallengeTheFriendFallback => 'your friend';

  @override
  String get friendChallengeYourCodeLabel => 'Your code';

  @override
  String get friendChallengeShareCodeButton => 'Share code';

  @override
  String friendChallengeWaitingForFriendToEnter(
    String friendName,
    String time,
  ) {
    return 'Waiting for $friendName to enter the code… $time';
  }

  @override
  String get friendChallengeWaitingEllipsis => 'Waiting…';

  @override
  String friendChallengeConditionsTitle(String mode) {
    return '$mode terms';
  }

  @override
  String friendChallengeInviteFromName(String name) {
    return 'Challenge from $name';
  }

  @override
  String friendChallengeJoinModeButton(String mode, String emoji) {
    return 'Join $mode $emoji';
  }

  @override
  String friendChallengeDeclinedTitle(String name) {
    return '$name declined the invite';
  }

  @override
  String get friendChallengeDeclinedMessage =>
      'You can try again later, or invite another friend.';

  @override
  String get friendChallengeExpiredTitle => 'Code expired';

  @override
  String get friendChallengeExpiredMessage =>
      'Your friend didn\'t join in time. You can create a new code.';

  @override
  String get friendChallengeNewCodeButton => 'Create a new code';

  @override
  String get friendChallengeWaitingTip1 =>
      'Tip: send your friend the code on WhatsApp - they\'ll type it in the \"I have a code\" screen';

  @override
  String get friendChallengeWaitingTip2 =>
      'Tip: the code is valid for 15 minutes - if it expires, just create a new one';

  @override
  String get friendChallengeWaitingTip3 =>
      'Tip: both players get exactly the same logos - whoever finishes first wins';

  @override
  String get friendChallengeWaitingTip4 =>
      'Tip: you can buy a cheap hint inside the duel if you get stuck';

  @override
  String get levelLoadingTitle => 'Preparing the level…';

  @override
  String get levelLoadingDidYouKnow => 'Did you know?';

  @override
  String get levelLoadingTip1 =>
      'A streak of 5 correct answers doubles the XP you\'ll get on the next level';

  @override
  String get levelLoadingTip2 =>
      'Out of coins? You can watch an ad and get a free letter hint';

  @override
  String get levelLoadingTip3 =>
      'Solving on your own (no hints) always earns more XP than solving with a hint';

  @override
  String get levelLoadingTip4 =>
      'In random challenge mode the streak is kept even when you leave - it only resets if you get a word wrong';

  @override
  String get levelLoadingTip5 =>
      'Every letter hint you use lowers the level\'s XP reward by one point';

  @override
  String get levelLoadingTip6 =>
      'You can invite friends to play and compete together for first place on the national leaderboard';

  @override
  String get appBottomNavShop => 'Shop';

  @override
  String get appBottomNavLeaderboard => 'Leaders';

  @override
  String get appBottomNavMissions => 'Missions';

  @override
  String get appBottomNavFriends => 'Friends';

  @override
  String get appBottomNavPlay => 'Play';

  @override
  String get appBottomNavHome => 'Home';

  @override
  String get appLoadingTitle => 'Guess the Logo!';

  @override
  String get appLoadingTitlePrefix => 'Guess the';

  @override
  String get appLoadingTitleMain => 'Logo!';

  @override
  String get appLoadingTagline =>
      'Thousands of logos are waiting for you. How many will you recognize?';

  @override
  String get appLoadingTipLabel => 'Tip';

  @override
  String get appLoadingTip1 => 'A streak of days doubles your daily bonus';

  @override
  String get appLoadingTip2 => 'Stuck? A hint reveals one letter of the answer';

  @override
  String get appLoadingTip3 => 'In a duel the winner takes the whole pot';

  @override
  String get appLoadingTip4 => 'Complete missions to level up your Logo Pass';

  @override
  String get mainCheckingVersion => 'Checking version...';

  @override
  String get mainConnectingToServer => 'Connecting to server...';

  @override
  String get mainCheckingActiveGame => 'Checking for an active game...';

  @override
  String get mainAlmostReady => 'Almost ready...';

  @override
  String get mainReady => 'Ready';

  @override
  String get mainScreenshotWarning =>
      'Note: screenshots from the game may not be shared outside the app';

  @override
  String mainReferralDownloadedSubtitle(String name) {
    return 'Because you downloaded the game through $name\'s invite! 🎉';
  }

  @override
  String get mainReferralFriendJoinedSubtitle =>
      'A friend joined the game through your invite! 🎉';

  @override
  String mainInviteFromName(String name) {
    return '$name is challenging you!';
  }

  @override
  String get mainNoHeadToHeadYet =>
      'You haven\'t played a duel against each other yet';

  @override
  String get mainInvitedToRace => 'Invited to a 1v1 logo race';

  @override
  String mainHeadToHeadBalance(int mine, int theirs, String side) {
    return 'Between you: $mine — $theirs $side';
  }

  @override
  String get mainTie => 'tied';

  @override
  String get mainInYourFavor => 'in your favor';

  @override
  String get mainInTheirFavor => 'in their favor';

  @override
  String get mainAcceptDuelChallenge => 'Accept the challenge ⚔';

  @override
  String get mainAcceptRaceChallenge => 'Accept the challenge 🏁';

  @override
  String mainAcceptCostWithEnergy(int cost, int energy) {
    return 'Costs $cost ⚡ · you have $energy';
  }

  @override
  String mainAcceptCost(int cost) {
    return 'Costs $cost ⚡';
  }

  @override
  String get mainDeclineButton => 'Decline';

  @override
  String get mainInviteBadge => '⚔ Duel invite';

  @override
  String get worldName1 => 'Companies Part A';

  @override
  String get worldName2 => 'Flags Part A';

  @override
  String get worldName3 => 'Apps';

  @override
  String get worldName4 => 'Vehicles';

  @override
  String get worldName5 => 'Authors';

  @override
  String get worldName6 => 'Well-Known Chains';

  @override
  String get worldName7 => 'Snacks & Candy';

  @override
  String get worldName8 => 'Soccer Clubs';

  @override
  String get worldName9 => 'Cities in Israel';

  @override
  String get worldName10 => 'Flags Part B';

  @override
  String get worldName11 => 'Banks & Insurance';

  @override
  String get worldName12 => 'Companies Part B';

  @override
  String get worldName13 => 'Well-Known Games';

  @override
  String get worldName14 => 'NBA Teams';

  @override
  String get worldName15 => 'IDF & Security Forces Units';

  @override
  String get worldName16 => 'Vehicles Part B';

  @override
  String get worldName17 => 'Electronics & Appliances';

  @override
  String get worldName18 => 'Israeli Media & News';

  @override
  String get worldName22 => 'NFL Teams';

  @override
  String get worldNameDefault => 'General';

  @override
  String get mainMenuCollected15Coins => 'You got 15 coins!';

  @override
  String get mainMenuCloseButton => 'Close';

  @override
  String mainMenuStreakDayTitle(int day) {
    return 'Day $day streak!';
  }

  @override
  String get mainMenuComeBackTomorrow =>
      'Come back tomorrow for a bigger prize';

  @override
  String get mainMenuEnergyLabel => 'Energy ';

  @override
  String get mainMenuCoinsLabel => 'Coins ';

  @override
  String get mainMenuCollectButton => 'Collect';

  @override
  String get mainMenuWelcomeTitle => 'Welcome!';

  @override
  String get mainMenuWelcomeSubtitle =>
      'Sign in so your progress is saved even if you switch devices, or just play';

  @override
  String get mainMenuPlayAsGuest => 'Play as guest';

  @override
  String get mainMenuTermsNotice =>
      'By continuing you agree to the terms of use and privacy policy';

  @override
  String get mainMenuSignInFailed => 'Sign-in failed, please try again later';

  @override
  String get mainMenuGoogleSignInFailed =>
      'Sign-in with Google failed - you can try again or play as a guest for now';

  @override
  String get mainMenuAppleSignInFailed =>
      'Sign-in with Apple failed - you can try again or play as a guest for now';

  @override
  String get mainMenuNameEntrySubtitle =>
      'What should we call you on the national leaderboard?';

  @override
  String get mainMenuLetsStartButton => 'Let\'s start ›';

  @override
  String get mainMenuSkipButton => 'Skip';

  @override
  String get mainMenuTourWelcomeTitle => 'Welcome to \"Guess the Logo!\" 🎉';

  @override
  String get mainMenuTourWelcomeBody =>
      'Let\'s quickly show you how the game works - it\'ll only take half a minute, and you can skip at any step.';

  @override
  String get mainMenuTourStep1Title => 'Play against others';

  @override
  String get mainMenuTourStep1Body =>
      'Duel, race, and duel series against real players in real time.';

  @override
  String get mainMenuTourStep2Title => 'Random challenge';

  @override
  String get mainMenuTourStep2Body =>
      'A random logo every time - solving correctly keeps the streak (🔥) you see here.';

  @override
  String get mainMenuTourStep3Title => 'This is where you start playing';

  @override
  String get mainMenuTourStep3Body =>
      'The \"Play level X\" button takes you to the levels screen, where you pick the world and the next logo to play. Tap the highlighted button to get started!';

  @override
  String mainMenuTourProgress(int step, int count) {
    return '$step of $count';
  }

  @override
  String get mainMenuTourTapHighlighted => 'Tap the highlighted card above';

  @override
  String get mainMenuTourNextButton => 'Next';

  @override
  String mainMenuLevelPill(int world, int sub, int count) {
    return 'Level $world • logo $sub of $count';
  }

  @override
  String get mainMenuNextLogoTeaser => 'Ready to identify the next logo?';

  @override
  String mainMenuPlayLevelButton(int world) {
    return 'Play level $world';
  }

  @override
  String get mainMenuDailyRewardClaimed =>
      'You got the prize - comes back tomorrow';

  @override
  String get mainMenuDailyUsedUp => 'Used up for today, try tomorrow';

  @override
  String mainMenuBpSubtitleWithClaims(int tier, int claims) {
    return 'Tier $tier • $claims prizes waiting';
  }

  @override
  String mainMenuBpTier(int tier) {
    return 'Tier $tier';
  }

  @override
  String get mainMenuRandomTitle => 'Random';

  @override
  String mainMenuRandomSubtitle(int streak) {
    return 'Random logo • streak $streak 🔥';
  }

  @override
  String get mainMenuRandomChallengeLabel => 'Random Challenge';

  @override
  String get mainMenuVsOthersTitle => 'Vs Others';

  @override
  String mainMenuVsOthersSubtitle(int count) {
    return '3 modes • $count online';
  }

  @override
  String get mainMenuBattlePassTitle => 'Logo Pass';

  @override
  String get mainMenuDailyChallengeTitle => 'Daily Challenge';

  @override
  String get mainMenuHelloFallback => 'Hello!';

  @override
  String mainMenuMedalsCount(int earned, int total) {
    return '🎖️ $earned/$total medals';
  }

  @override
  String mainMenuMoreTime(String time) {
    return '$time more';
  }

  @override
  String get mainMenuContinuingLabel => 'Continuing';

  @override
  String mainMenuWorldStepLabel(String worldName, int sub) {
    return '$worldName · step $sub';
  }

  @override
  String get mainMenuPlayVsOthersTitle => 'Play vs others';

  @override
  String get mainMenuDuelRaceNote => 'Duel · Race';

  @override
  String get mainMenuRandomNote => 'Random logo · keeps your streak';

  @override
  String get mainMenuLogoRaceTitle => 'Logo Race 🏁';

  @override
  String get mainMenuLogoRaceSubtitle => '1v1 · whoever guesses first wins';

  @override
  String get mainMenuPlayButton => 'Play';

  @override
  String mainMenuEnergyRewardMessage(int amount) {
    return 'You got $amount energy! ⚡';
  }

  @override
  String get mainMenuDailyChallengeSubtitleDone =>
      'Daily challenge · you got the prize - comes back tomorrow';

  @override
  String get mainMenuDailyChallengeSubtitleUsedUp =>
      'Daily challenge · used up for today, try tomorrow';

  @override
  String mainMenuDailyChallengeSubtitleDefault(int count) {
    return 'Daily challenge · $count logos';
  }

  @override
  String get mainMenuDoneCheckLabel => 'Done ✓';

  @override
  String get mainMenuReminderLabel => 'Reminder';

  @override
  String get mainMenuMaxLabel => 'Max';

  @override
  String mainMenuClaimsCount(int claims) {
    return '$claims prizes';
  }

  @override
  String get mainMenuAlreadyClaimedToday =>
      'Already collected today - come back tomorrow for the next prize';

  @override
  String get mainMenuDiamondWonToday =>
      'Congrats - you won the day 7 diamond pack!';

  @override
  String get mainMenuDiamondTodayIsDay7 =>
      'Today\'s the big day - day 7 and the diamond pack!';

  @override
  String get mainMenuDiamondOneDayLeft =>
      'One more day - and you get a diamond pack';

  @override
  String mainMenuDiamondDaysLeft(int days) {
    return '$days more days - and you get a diamond pack';
  }

  @override
  String get mainMenuTodaysRewardLabel => 'Today\'s prize';

  @override
  String get mainMenuReminderTomorrow8pm => 'Reminder tomorrow · 20:00';

  @override
  String get mainMenuNeedEnergyTitle => 'Need energy?';

  @override
  String mainMenuWatchAdEnergySubtitle(int amount) {
    return 'Watch an ad - get $amount energy instantly';
  }

  @override
  String get mainMenuWatchButton => 'Watch';

  @override
  String get mainMenuAdBonusTitle => 'Ad bonus';

  @override
  String get mainMenuWatchAdCoinsSubtitle => 'Watch an ad - get 15 coins';

  @override
  String mainMenuAvailableAgainIn(String time) {
    return 'Available again in $time';
  }

  @override
  String get mainMenuWaitingLabel => 'Waiting';

  @override
  String get mainMenuWaitingLabel2 => 'Waiting';

  @override
  String mainMenuInviteShareText(String ios, String android) {
    return 'Come play with me 🎮 \"Guess the Logo!\" - who knows the most logos? 🔥\n\n📱 iPhone: $ios\n🤖 Android/Galaxy: $android';
  }

  @override
  String get mainMenuNameHint => 'Type your name here...';

  @override
  String get mainMenuCheckingAvailability => 'Checking availability...';

  @override
  String get mainMenuNameAvailable => 'Name available';

  @override
  String get mainMenuNameTaken => 'This name is already taken, try another one';

  @override
  String get achievementsTitle => 'Achievements & Medals';

  @override
  String achievementsEarnedCount(int earned, int total) {
    return '$earned of $total medals';
  }

  @override
  String get achievementsDescription =>
      'Every achievement gives coins. Your progress is counted here, no matter how much XP others have.';

  @override
  String achievementsClaimedMessage(int coins, String title) {
    return 'You got $coins coins for \"$title\"';
  }

  @override
  String get dailyChallengeTitle => 'Daily Challenge';

  @override
  String get dailyChallengeAlreadyDoneTitle =>
      'You already completed today\'s challenge!';

  @override
  String get dailyChallengeComeBackTomorrow =>
      'A new logo and a new challenge await you tomorrow';

  @override
  String get dailyChallengeUsedUpTitle =>
      'You already tried today\'s challenge';

  @override
  String get dailyChallengeUsedUpMessage =>
      'There\'s only one attempt per day - try again tomorrow with a new challenge';

  @override
  String dailyChallengeIntroStats(int count, int seconds) {
    return '$count logos · $seconds seconds total';
  }

  @override
  String get dailyChallengeIntroBody =>
      'Solve all the logos in a row before time runs out and win a bonus. No hints in this screen - it\'s a pure speed test!';

  @override
  String get dailyChallengeOneAttemptWarning =>
      '⚠️ You only have one attempt per day - even if you fail';

  @override
  String get dailyChallengeStartButton => 'Ready? Start! ⚡';

  @override
  String get dailyChallengeSuccessTitle => 'Well done! 🎉';

  @override
  String dailyChallengeSuccessTime(String seconds) {
    return 'You finished today\'s challenge in $seconds seconds';
  }

  @override
  String get dailyChallengeTimeUpTitle => 'Time\'s up! ⏱️';

  @override
  String dailyChallengeFailedProgress(int current, int total) {
    return 'You reached logo $current of $total - you used your only attempt for today';
  }

  @override
  String get dailyChallengeTryTomorrow =>
      'Try again tomorrow with a new challenge';

  @override
  String get dailyChallengeReminderSet => 'We\'ll remind you tomorrow!';

  @override
  String get dailyChallengeRemindMe => 'Remind me tomorrow';

  @override
  String get worldName19 => 'Flags Part C';

  @override
  String get worldName20 => 'Electronics & Appliances Part B';

  @override
  String get worldName21 => 'European Basketball (EuroLeague)';

  @override
  String get worldName23 => 'Israeli Soccer Clubs';

  @override
  String get worldName24 => 'Movies & Entertainment';

  @override
  String get worldName25 => 'Airlines';

  @override
  String get worldName26 => 'European Football Clubs Part B';

  @override
  String get levelsUnlockPriceFallback => '₪2.90';

  @override
  String levelsUnlockDialogTitle(int world) {
    return 'Level $world is locked';
  }

  @override
  String levelsUnlockDialogBodyNext(String price) {
    return 'You can unlock it now for $price,\nor just finish the previous level.';
  }

  @override
  String levelsUnlockDialogBodyFar(
    String price,
    int world,
    int needed,
    int next,
  ) {
    return 'Unlocking a level costs $price.\nTo reach level $world you need to unlock $needed levels,\none after another - starting with level $next.';
  }

  @override
  String get levelsNotNowButton => 'Not now';

  @override
  String levelsUnlockButton(int next, String price) {
    return 'Unlock level $next  •  $price';
  }

  @override
  String get levelsUnlockUnavailable =>
      'Unlocking levels isn\'t available right now, try again later';

  @override
  String get levelsChooseLevelTitle => 'Choose a Level';

  @override
  String levelsCountSubtitle(int total, int unlocked) {
    return '$total levels · $unlocked unlocked';
  }

  @override
  String levelsDifficultyLabel(int level) {
    return 'Difficulty $level';
  }

  @override
  String get levelsLockedSubtitle => 'Locked · can be unlocked for a fee';

  @override
  String levelsSolvedOfTotal(int solved, int total) {
    return '$solved of $total stages';
  }

  @override
  String get levelsTourTitle => 'Levels screen';

  @override
  String get levelsTourBody =>
      'Each world unlocks automatically as soon as you finish the previous one - no extra action needed.';

  @override
  String get levelsTourContinueButton => 'Continue ›';

  @override
  String get levelsTourTapHighlighted =>
      'Tap the highlighted world to continue';

  @override
  String subLevelsCategoryStageLabel(String category, int stage) {
    return '$category · Stage $stage';
  }

  @override
  String get subLevelsLockedMessage =>
      'This one\'s locked! Solve the previous ones first.';

  @override
  String get subLevelsAlreadyFoundMessage => 'You already found this logo!';

  @override
  String get subLevelsYourProgressTitle => 'Your progress';

  @override
  String get subLevelsAllCompletedMessage => 'All stages completed!';

  @override
  String subLevelsNextStageMessage(int stage) {
    return 'Next stage: stage $stage';
  }

  @override
  String subLevelsDoneCount(int count) {
    return '✓ $count completed';
  }

  @override
  String subLevelsRemainingCount(int count) {
    return '· $count stages left';
  }

  @override
  String subLevelsCategoryWorldLabel(String category, int world) {
    return '$category · Level $world';
  }

  @override
  String subLevelsDoneOfTotal(int done, int total) {
    return '$done of $total stages completed';
  }

  @override
  String subLevelsContinueToStage(int stage) {
    return 'Continue to stage $stage';
  }

  @override
  String get subLevelsTourTitle => 'Stages';

  @override
  String get subLevelsTourBody =>
      'Each stage unlocks automatically as soon as you solve the previous one - no extra action needed.';

  @override
  String get subLevelsTourTapHighlighted =>
      'Tap the highlighted stage to start playing';

  @override
  String get subLevelsPlayLabel => 'Play';

  @override
  String get logoLevelAnonymousPlayerFallback => 'Anonymous player';

  @override
  String get logoLevelStuckTipOnboarding => 'You can buy a hint with coins 💡';

  @override
  String get logoLevelStuckTipHasHint => 'You have a hint! 💡';

  @override
  String get logoLevelStuckTipFreeAd => 'Ad = free hint 🎬';

  @override
  String get logoLevelStuckTipTapLamp => 'Tap the lamp 💡';

  @override
  String get logoLevelNoInternetTitle => 'No internet connection';

  @override
  String get logoLevelNoInternetBody =>
      'You need an active internet connection to play. Check your WiFi or mobile data and try again.';

  @override
  String get logoLevelTryAgainButton => 'Try again';

  @override
  String get logoLevelRandomCompleteTitle => 'Wow! 🎉';

  @override
  String get logoLevelRandomCompleteBody =>
      'You solved all the logos in random mode!';

  @override
  String get logoLevelBackToMainScreenButton => 'Back to main screen';

  @override
  String get logoLevelAboutTitle => 'About the app';

  @override
  String get logoLevelAboutBody =>
      'All logos shown in this app belong to their respective owners. Use of logos for identification purposes only is done under the \'fair use\' principle. This app is not affiliated with, sponsored by, or endorsed by the companies shown.';

  @override
  String get logoLevelCloseButton => 'Close';

  @override
  String get logoLevelNoAdAvailable =>
      'No ad available right now, try again in a moment';

  @override
  String get logoLevelNotEnoughCoinsTitle => 'You don\'t have enough coins';

  @override
  String logoLevelNotEnoughCoinsBody(int cost, int coins) {
    return 'This hint costs $cost coins and you only have $coins';
  }

  @override
  String logoLevelMissingCoins(int amount) {
    return '$amount missing';
  }

  @override
  String get logoLevelGoToShopButton => 'Go to coin shop';

  @override
  String get logoLevelOrDivider => 'or';

  @override
  String get logoLevelWatchAdButton => 'Watch an ad 🎬';

  @override
  String get logoLevelAdHintDescription =>
      'Reveals just one letter - doesn\'t solve the whole word';

  @override
  String get logoLevelAdHintAlreadyUsed =>
      'You already used an ad-hint on this stage 🎬';

  @override
  String get logoLevelHintConfirmTitle => 'Buy this hint?';

  @override
  String logoLevelHintConfirmBody(int cost) {
    return 'This will cost you $cost coins.';
  }

  @override
  String get logoLevelHintConfirmButton => 'Yes, buy it';

  @override
  String get logoLevelChooseHintTitle => 'Choose a hint';

  @override
  String get logoLevelRevealNextLetterTitle => 'Reveal the next letter';

  @override
  String get logoLevelRevealNextLetterSubtitle =>
      'One more letter is revealed immediately';

  @override
  String get logoLevelSolveWholeWordTitle => 'Solve the whole word';

  @override
  String get logoLevelSolveWholeWordSubtitle =>
      'All the letters are revealed at once';

  @override
  String get logoLevelWatchAdTitle => 'Watch an ad';

  @override
  String get logoLevelWatchAdSubtitle => 'Get one letter for free';

  @override
  String logoLevelNewStreakRecord(int streak) {
    return 'New streak record: $streak!';
  }

  @override
  String get logoLevelRepeatedScreenshotMessage =>
      'Another screenshot detected - moving to the next stage';

  @override
  String get logoLevelLevelCompleteTitle => 'Well done! 🎉';

  @override
  String logoLevelLevelCompleteBody(int level) {
    return 'You successfully finished level $level';
  }

  @override
  String logoLevelNextLevelButton(int level) {
    return 'To level $level ›';
  }

  @override
  String get logoLevelFinishButton => 'Finish';

  @override
  String get logoLevelCorrectTitle => 'Well done!';

  @override
  String get logoLevelWrongTitle => 'Wrong name';

  @override
  String get logoLevelOnboardingCorrectTip =>
      'That\'s exactly how you play! Every correct answer earns you experience points (XP) and coins';

  @override
  String get logoLevelNextStageButton => 'Continue to next stage ›';

  @override
  String logoLevelStreakHeader(int streak) {
    return '🔥 Streak $streak';
  }

  @override
  String get logoLevelRandomChallengeHeader => 'Random challenge';

  @override
  String get logoLevelHintChipLabel => 'Hint';

  @override
  String get logoLevelTourStep1Title => 'Where you are';

  @override
  String get logoLevelTourStep1Body =>
      'Here you see the category and current stage - every logo you solve advances you to the next stage.';

  @override
  String get logoLevelTourStep2Title => 'Identify the logo';

  @override
  String get logoLevelTourStep2Body =>
      'This is the logo you need to identify and write its name.';

  @override
  String get logoLevelTourStep3Title => 'Here\'s your answer';

  @override
  String get logoLevelTourStep3Body =>
      'Every letter you type appears here. Tap a letter you already typed to delete just that one.';

  @override
  String get logoLevelTourStep4Title => 'Here\'s where you type';

  @override
  String get logoLevelTourStep4Body =>
      'Tap the letters here to fill in the answer - in the order they appear in the word.';

  @override
  String logoLevelTourStepCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get logoLevelTourNextButton => 'Next';

  @override
  String get logoLevelTourTapLetterToStart => 'Tap a letter to start';

  @override
  String get logoLevelFreeLabel => 'Free';

  @override
  String get friendsNowFriendsMessage => 'You\'re friends now!';

  @override
  String friendsInviteText(String link, int bonus) {
    return 'Come play with me in \"Guess the Logo!\" 🎮 - who knows the most logos? 🔥\n\n$link\n\nWe both get $bonus coins as a gift as soon as you install it ✨';
  }

  @override
  String get friendsShareFallbackCopiedWithPaste =>
      'No sharing app found - the message was copied, you can paste and send it';

  @override
  String get friendsShareFallbackCopied =>
      'No sharing app found - the message was copied';

  @override
  String friendsShareCodeText(String code, String iosLink, String androidLink) {
    return 'Let\'s be friends in \"Guess the Logo!\" 🎮\nMy code: $code\n(Open the app -> Friends -> \"I have a code\" and enter it)\n\nHaven\'t downloaded yet? 📱 iPhone: $iosLink\n🤖 Android/Galaxy: $androidLink';
  }

  @override
  String get friendsShareCodeSubject => 'Let\'s be friends!';

  @override
  String get friendsCodeCopiedMessage => 'Code copied!';

  @override
  String friendsCodeLengthError(int length) {
    return 'Code must be $length characters long';
  }

  @override
  String get friendsRequestSentMessage =>
      'Friend request sent! We\'ll wait for them to accept';

  @override
  String get friendsAlreadyRequestedError =>
      'You already sent them a request - waiting for approval';

  @override
  String get friendsAlreadyFriendsError => 'You\'re already friends with them';

  @override
  String get friendsOwnCodeError =>
      'This is your own code - send it to a friend, don\'t enter it here';

  @override
  String get friendsCodeNotFoundError =>
      'No such code found - make sure you typed it correctly';

  @override
  String get friendsInvalidCodeError => 'Invalid code';

  @override
  String get friendsGenericErrorLater =>
      'Something went wrong - try again later';

  @override
  String get friendsTopBarTitle => 'Friends';

  @override
  String get friendsHeroTitle => 'Play with friends';

  @override
  String get friendsHeroSubtitle =>
      'Add friends by code, see who\'s online, and invite them straight to a game';

  @override
  String get friendsMyCodeTitle => 'Your code';

  @override
  String get friendsMyCodeHint =>
      'To connect with a friend who already plays - no reward. To invite a new friend and earn coins, scroll down 👇';

  @override
  String get friendsShareCodeButton => 'Share code';

  @override
  String get friendsAddFriendPrompt => 'Have a friend\'s code?';

  @override
  String get friendsAddButton => 'Add';

  @override
  String get friendsPendingRequestsTitle => 'Friend requests';

  @override
  String get friendsMyFriendsTitle => 'My friends';

  @override
  String get friendsEmptyListMessage =>
      'You don\'t have any friends here yet - share your code above to get started';

  @override
  String get friendsOnlineStatus => 'Online';

  @override
  String get friendsOfflineStatus => 'Offline';

  @override
  String get friendsInviteButtonLabel => 'Invite to play';

  @override
  String get friendsRemoveConfirmTitle => 'Remove from friends?';

  @override
  String friendsRemoveConfirmBody(String name) {
    return '$name will be removed from your friends list, and you\'ll be removed from theirs. You can reconnect later with a new code.';
  }

  @override
  String get friendsRemoveButton => 'Remove';

  @override
  String friendsRemovedMessage(String name) {
    return '$name was removed from your friends';
  }

  @override
  String get friendsLeaderboardTitle => 'Who\'s leading among your friends';

  @override
  String friendsLeaderboardYouRow(String name) {
    return '$name (you)';
  }

  @override
  String get friendsInviteCardTitle => 'Invite to play';

  @override
  String friendsInviteCardBody(int bonus) {
    return 'Send your friends a link to download the app - WhatsApp, text messages, or any other app. You\'ll both get $bonus coins automatically once they install it!';
  }

  @override
  String get friendsSendInviteButton => 'Send invite';

  @override
  String get friendsExplainerTitle => 'Friends screen';

  @override
  String get friendsExplainerCodeTitle => 'Personal code to share';

  @override
  String get friendsExplainerCodeBody =>
      'Share your code with friends so they can add you.';

  @override
  String get friendsExplainerOnlineTitle => 'Who\'s online now';

  @override
  String get friendsExplainerOnlineBody =>
      'A green dot next to a friend shows they\'re currently in the app.';

  @override
  String get friendsExplainerInviteTitle => 'Invite to play';

  @override
  String get friendsExplainerInviteBody =>
      'Tap \"Invite to play\" next to any friend to challenge them directly to a duel.';

  @override
  String get leaderboardLoadErrorGeneric =>
      'We couldn\'t load the leaderboard. Check your internet connection and try again.';

  @override
  String leaderboardLoadErrorWithDetail(String error) {
    return 'We couldn\'t load the leaderboard.\n\nTechnical error (temporary diagnostic):\n$error';
  }

  @override
  String get leaderboardExplainerTitle => 'Leaderboard';

  @override
  String get leaderboardExplainerMedalsTitle => 'Ranked by medals';

  @override
  String get leaderboardExplainerMedalsBody =>
      'The default - a fair ranking based on achievements, not just how many games you played.';

  @override
  String get leaderboardExplainerPointsTitle => 'You can also rank by points';

  @override
  String get leaderboardExplainerPointsBody =>
      'The switch above changes the ranking to total XP earned.';

  @override
  String get leaderboardExplainerPositionTitle =>
      'Your position is always visible';

  @override
  String get leaderboardExplainerPositionBody =>
      'Even if you\'re not in the top ten - a floating badge shows where you are.';

  @override
  String get leaderboardHeaderTitle => 'Leaderboard';

  @override
  String get leaderboardWeeklyLeagueChip => 'Weekly league';

  @override
  String get leaderboardAchievementsChip => 'Achievements';

  @override
  String get leaderboardMedalsModeLabel => 'Medals';

  @override
  String get leaderboardPointsModeLabel => 'Points';

  @override
  String get leaderboardEmptyMessage =>
      'No scores on the leaderboard yet.\nBe the first to solve a logo!';

  @override
  String leaderboardTopByMedals(int count) {
    return 'Top $count by medals';
  }

  @override
  String leaderboardTopOverall(int count) {
    return 'Top $count';
  }

  @override
  String get leaderboardYourRankDivider => 'Your rank';

  @override
  String get leaderboardYourXpLabel => 'Your XP';

  @override
  String get leaderboardStreakLabel => 'Streak';

  @override
  String leaderboardFloatingYouRow(String name) {
    return '$name  (you)';
  }

  @override
  String get leaderboardTapToScrollHint => 'Tap to scroll to your spot';

  @override
  String get leagueScreenTitle => 'Weekly league';

  @override
  String leagueRolloverSummaryTitle(int rank, int total) {
    return 'Week summary: rank $rank of $total';
  }

  @override
  String leaguePointsLastWeek(int points) {
    return '$points points last week.';
  }

  @override
  String leagueCoinsReceived(int coins) {
    return 'You received $coins coins.';
  }

  @override
  String leagueTierUp(String tier) {
    return 'You moved up to the $tier league!';
  }

  @override
  String leagueTierDown(String tier) {
    return 'You moved down to the $tier league. Come back stronger.';
  }

  @override
  String leagueTierSame(String tier) {
    return 'You stayed in the $tier league.';
  }

  @override
  String get leagueGreatButton => 'Great';

  @override
  String get leagueEndsNow => 'Ends now';

  @override
  String leagueEndsInDaysHours(int days, int hours) {
    return 'Ends in $days days and $hours hours';
  }

  @override
  String leagueEndsInHours(int hours) {
    return 'Ends in $hours hours';
  }

  @override
  String leagueTierNameLabel(String tier) {
    return '$tier league';
  }

  @override
  String leagueMyRankPoints(int rank, int points) {
    return 'Rank $rank · $points points';
  }

  @override
  String leaguePointsOnly(int points) {
    return '$points points';
  }

  @override
  String get leagueExplanationBody =>
      'Every week starts from zero, competing against players in the same league. Places 1-3: 100 / 60 / 40 coins, plus moving up a league. Play, solve logos and win to earn points.';

  @override
  String get leagueEmptyMessage =>
      'No one has earned points this week yet. Be the first!';

  @override
  String get leaguePlayerFallbackName => 'Player';

  @override
  String get leaguePointsAbbrev => 'pts';

  @override
  String missionsLoadError(String error) {
    return 'Error loading missions: $error';
  }

  @override
  String missionsClaimedCoinsMessage(int amount) {
    return 'You got +$amount coins!';
  }

  @override
  String get missionsRerollUnavailable => 'Can\'t swap this mission right now';

  @override
  String missionsRerollSuccess(String title) {
    return 'Mission swapped: $title';
  }

  @override
  String get missionsScreenTitle => 'Missions';

  @override
  String get missionsUnknownError => 'Unknown error';

  @override
  String get missionsExplainerTitle => 'Missions screen';

  @override
  String get missionsExplainerDailyWeeklyTitle => 'Daily and weekly missions';

  @override
  String get missionsExplainerDailyWeeklyBody =>
      'Every mission you complete earns a reward - coins or XP points.';

  @override
  String get missionsExplainerChallengeTitle => 'Daily challenge';

  @override
  String get missionsExplainerChallengeBody =>
      'Appears at the top every day - a one-time chance for a bigger reward.';

  @override
  String get missionsExplainerResetTitle => 'Resets automatically';

  @override
  String get missionsExplainerResetBody =>
      'New missions are waiting every day/week - no need to do anything.';

  @override
  String get missionsWeeklyTab => 'Weekly';

  @override
  String get missionsDailyTab => 'Daily';

  @override
  String get missionsResetsNextWeek => 'Resets at the start of next week';

  @override
  String missionsResetsInHours(String time) {
    return 'Resets in $time hours';
  }

  @override
  String get missionsCompleteDailyChallengeTitle =>
      'Complete the daily challenge';

  @override
  String get missionsPremiumBadge => '⭐ Premium';

  @override
  String get missionsClaimedLabel => 'Claimed';

  @override
  String get missionsClaimButton => 'Claim reward';

  @override
  String get missionsPremiumRequiredReady =>
      'Reward ready - requires Logo Pass premium to claim';

  @override
  String get missionsPremiumRequired => 'Requires Logo Pass premium';

  @override
  String get missionsWatchAdRerollButton => 'Ad = swap mission';

  @override
  String get battlePassPurchaseUnavailable =>
      'Purchase isn\'t available right now - try again in a moment';

  @override
  String get battlePassUpgradeDialogTitle => 'Upgrade to premium?';

  @override
  String battlePassUpgradeDialogBody(String price) {
    return 'You\'ll get all the premium rewards for the season, including ones you\'ve already unlocked, for $price.';
  }

  @override
  String battlePassUpgradeConfirmButton(String price) {
    return 'Yes, upgrade · $price';
  }

  @override
  String get battlePassUpsellTitle => 'Logo Pass Premium';

  @override
  String battlePassUpsellBody(int tiers, int coins) {
    return 'Unlocks $tiers more rewards throughout the season - about $coins coins';
  }

  @override
  String battlePassUpsellEnergySuffix(int energy) {
    return ' and $energy energy';
  }

  @override
  String battlePassUpsellBoostSuffix(int minutes) {
    return ' + a free-hints boost for $minutes minutes';
  }

  @override
  String get battlePassUpsellBodySuffix =>
      ' in total, on top of everything you already get on the free track.';

  @override
  String battlePassUpgradeNowButton(String price) {
    return 'Upgrade now · $price';
  }

  @override
  String get battlePassMaybeLaterButton => 'Maybe later';

  @override
  String get battlePassInfoDialogTitle => 'What is the Logo Pass?';

  @override
  String get battlePassInfoDialogBody =>
      'Earn points from missions and the daily challenge, and level up throughout the season. Each tier unlocks a reward on the free track, and premium owners get a bigger reward at the same tier. A new season starts from 0 at the beginning of every month.';

  @override
  String get battlePassGotItButton => 'Got it';

  @override
  String get battlePassScreenTitle => 'Logo Pass';

  @override
  String battlePassSeasonNumberLabel(int number) {
    return 'Season $number';
  }

  @override
  String get battlePassSeasonEndsToday => 'The season ends today';

  @override
  String battlePassDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get battlePassLastTierLabel => 'Final tier!';

  @override
  String battlePassPointsToNextTier(int points) {
    return '$points more ⭐';
  }

  @override
  String get battlePassTierLabel => 'Tier';

  @override
  String battlePassPendingRewards(int count) {
    return '$count rewards to claim';
  }

  @override
  String get battlePassAllClaimed => 'All claimed ✓';

  @override
  String get battlePassSeasonBadgeDecorative => '🏅 End-of-season badge';

  @override
  String battlePassUpgradeCtaTitle(String price) {
    return 'Upgrade to premium · $price';
  }

  @override
  String battlePassUpgradeCtaSubtitleWithReached(int locked, int reached) {
    return 'Unlocks $locked rewards · including $reached you already earned';
  }

  @override
  String battlePassUpgradeCtaSubtitle(int locked) {
    return 'Unlocks $locked more rewards';
  }

  @override
  String get battlePassPremiumColumnLabel => 'Premium';

  @override
  String get battlePassClaimButton => 'Claim';

  @override
  String get battlePassPopupPremiumPathLabel => 'Premium track';

  @override
  String get battlePassPopupFreePathLabel => 'Free track';

  @override
  String battlePassPopupHeaderLabel(int tier) {
    return 'Logo Pass · Tier $tier';
  }

  @override
  String get battlePassPopupRewardClaimedTitle => 'Reward claimed!';

  @override
  String battlePassPopupCoinsAmount(int coins) {
    return '$coins coins';
  }

  @override
  String battlePassPopupEnergyAmount(int energy) {
    return '$energy energy';
  }

  @override
  String battlePassPopupPathTierLabel(String path, int tier) {
    return '$path · Tier $tier';
  }

  @override
  String get battlePassPopupBackToPassButton => 'Back to pass';

  @override
  String get battlePassPopupAllTiersUnlocked => 'All tiers unlocked!';

  @override
  String battlePassPopupProgressToTier(int tier) {
    return 'Progress to tier $tier';
  }

  @override
  String get battlePassPopupMaxStars => '⭐ Max';

  @override
  String battlePassPopupPercentStars(int percent) {
    return '⭐ $percent%';
  }

  @override
  String get battlePassPopupPremiumTeaserTitle =>
      'With premium you\'d get this at this tier';

  @override
  String battlePassPopupPremiumMultiplier(String multiplier) {
    return ' · ${multiplier}x what you got';
  }

  @override
  String battlePassPopupTierUnlockedTitle(int tier) {
    return 'Tier $tier unlocked';
  }

  @override
  String battlePassPopupClaimTierButton(int tier) {
    return 'Claim tier $tier';
  }

  @override
  String battlePassBoostPillLabel(int minutes) {
    return '${minutes}m';
  }

  @override
  String battlePassBoostRewardTitle(int minutes) {
    return '$minutes minutes of free hints';
  }

  @override
  String get promoLogoPassBody =>
      '🎫 Unlock more and more rewards all season long - don\'t miss out!';

  @override
  String get promoShopBody =>
      '🛍️ Coins, ad removal and more - come see what\'s in the shop';

  @override
  String shopCouponRedeemedMessage(int coins) {
    return 'Code redeemed! You got $coins coins';
  }

  @override
  String get shopCouponNotFound =>
      'Code doesn\'t exist - check that you typed it correctly';

  @override
  String get shopCouponInactive => 'This code is no longer active';

  @override
  String get shopCouponUsedUp =>
      'This code has been fully used by other players';

  @override
  String get shopCouponAlreadyUsed => 'You already redeemed this code before';

  @override
  String shopCouponGenericError(String detail) {
    return 'Error: $detail';
  }

  @override
  String get shopUnknownErrorDetail => 'Unknown';

  @override
  String get shopAdBonusResetSubtitle => 'Comes back again in 3 hours';

  @override
  String shopNextAdAvailableIn(String time) {
    return 'You can watch another ad in $time';
  }

  @override
  String shopCoinsAmountLabel(String amount) {
    return '$amount coins';
  }

  @override
  String shopEnergyAmountLabel(String amount) {
    return '$amount energy';
  }

  @override
  String get shopFirstPurchaseBonusDesc => 'First purchase bonus - double!';

  @override
  String get shopCoinsPackDesc => 'Coins package';

  @override
  String get shopCoinsPackBestValueDesc => 'Coins package - best value';

  @override
  String get shopEnergyPackDesc => 'Energy package';

  @override
  String get shopNoAdsMonthlyName => 'No ads - monthly';

  @override
  String get shopMonthlySubscriptionDesc => 'Monthly subscription';

  @override
  String get shopNoAdsLifetimeName => 'No ads - lifetime';

  @override
  String get shopOneTimePurchaseDesc => 'One-time purchase';

  @override
  String get shopAllAdsRemovedLabel => 'All ads removed';

  @override
  String get shopCoinsLabel => 'Coins';

  @override
  String get shopEnergyLabel => 'Energy';

  @override
  String shopDoubleBonusValue(int amount) {
    return '+$amount 🎁';
  }

  @override
  String get shopCannotOpenLinkError => 'Can\'t open the link right now';

  @override
  String get shopPurchaseUnavailable =>
      'Purchase isn\'t available right now, try again later';

  @override
  String get shopStarterPackWaitingTitle =>
      'A starter pack is waiting for you!';

  @override
  String shopStarterPackEnergySuffix(int energy) {
    return ' + $energy energy';
  }

  @override
  String shopStarterPackTimeLeft(String time) {
    return '$time left - for 3 hours only';
  }

  @override
  String get shopScreenTitle => 'Shop';

  @override
  String get shopQuickActionsSection => 'Quick actions';

  @override
  String get shopCouponHint => 'Enter coupon code';

  @override
  String get shopRedeemButton => 'Redeem';

  @override
  String get shopWatchAdGet15CoinsTitle => 'Watch an ad - get 15 coins';

  @override
  String get shopAdBonusAvailableSubtitle =>
      'Available again every 3 hours - free coins';

  @override
  String get shopNextBonusAvailableInLabel => 'Next bonus available in: ';

  @override
  String shopWatchAdGetEnergyTitle(int amount) {
    return 'Watch an ad - get $amount energy';
  }

  @override
  String get shopEnergyAdUnlimitedSubtitle =>
      'No limit on times - always available when energy isn\'t full';

  @override
  String get shopBoostSectionTitle => 'Boosts';

  @override
  String get shopBoostHintsTitle => '15 minutes of free hints';

  @override
  String get shopBoostHintsSubtitle =>
      'Up to 2 free letter hints per puzzle - no coins, no reward penalty';

  @override
  String get shopBoostDoubleTitle => '15 minutes of double points';

  @override
  String get shopBoostDoubleSubtitle =>
      'All XP you earn from solving levels is doubled';

  @override
  String shopBoostActiveLabel(String time) {
    return 'Active - $time left';
  }

  @override
  String get shopBoostAlreadyActiveToast =>
      'You already have an active boost right now';

  @override
  String get shopBoostNotEnoughCoinsToast =>
      'You don\'t have enough coins for this boost';

  @override
  String get shopBoostHintsActivatedToast =>
      '🔥 Free hints activated for 15 minutes!';

  @override
  String get shopBoostDoubleActivatedToast =>
      '⚡ Double points activated for 15 minutes!';

  @override
  String shopBoostFreeTrialToast(int minutes) {
    return '🎁 Gift! Free hints for $minutes minutes - try it now';
  }

  @override
  String get shopCoinsSectionTitle => 'Coin shop';

  @override
  String get shopLegendPackTitle => 'Legend pack';

  @override
  String get shopGoldPackTitle => 'Gold pack';

  @override
  String get shopFirstPurchaseDoubleBadge => 'First time = double!';

  @override
  String get shopBeginnerPackTitle => 'Beginner pack';

  @override
  String get shopKingsPackTitle => 'Kings pack';

  @override
  String get shopVipPackTitle => 'VIP pack';

  @override
  String get shopMostPopularBadge => 'Most popular';

  @override
  String get shopEnergySectionTitle => 'Energy shop';

  @override
  String get shopEnergySmallTitle => 'Small charge';

  @override
  String get shopEnergyMediumTitle => 'Medium charge';

  @override
  String get shopEnergyLargeTitle => 'Large charge';

  @override
  String get shopEnergyHugeTitle => 'Huge charge';

  @override
  String get shopNoAdsSectionTitle => 'No ads';

  @override
  String get shopNoAdsActiveMessage =>
      'No-ads mode is active! Thanks for the support 💜';

  @override
  String get shopMonthlySubTitle => 'Monthly subscription';

  @override
  String get shopMonthlySubSubtitle =>
      'No ads between stages, renews every month';

  @override
  String get shopLifetimeTitle => 'For life';

  @override
  String get shopLifetimeSubtitle => 'One payment - no ads forever';

  @override
  String get shopBestValueBadge => 'Best value';

  @override
  String get shopPrivacyPolicyLink => 'Privacy policy';

  @override
  String get shopCheckingPurchasesMessage => 'Checking previous purchases...';

  @override
  String get shopRestorePurchasesButton => 'Restore purchases';

  @override
  String get shopRecommendedForYouBadge => 'Recommended for you';

  @override
  String get shopTournamentBonusBannerTitle =>
      'Champion deal! +25% coins on the big packs';

  @override
  String shopTournamentBonusTimeLeft(String time) {
    return '$time left for the champion deal';
  }

  @override
  String get shopTournamentBonusTileNote => 'Champion bonus: +25% coins';

  @override
  String get shopTournamentBonusBadge => 'Champion bonus +25%';

  @override
  String shopTournamentBonusValue(int amount) {
    return '+$amount - champion bonus!';
  }

  @override
  String get shopTournamentBonusDesc => 'Champion bonus - 25% more coins!';

  @override
  String get rewardPopupEnergyDefaultSubtitle => 'Enough for two more duels';

  @override
  String get rewardPopupGotLabel => 'You got';

  @override
  String get rewardPopupYourEnergyLabel => 'Your energy';

  @override
  String get rewardPopupToDuelButton => 'Let\'s go, to the duel ⚔';

  @override
  String get rewardPopupContinueLink => 'Continue';

  @override
  String get rewardPopupYourCoinsLabel => 'Your coins';

  @override
  String get rewardPopupToShopLink => 'To the shop';

  @override
  String get rewardPopupPurchaseCompleteTitle => 'Purchase complete!';

  @override
  String get rewardPopupItemsInAccountSubtitle =>
      'The items are already in your account';

  @override
  String get rewardPopupAddedToAccountLabel => 'Added to your account';

  @override
  String get rewardPopupBackToGameButton => 'Great, back to the game';

  @override
  String get reviewPromptTitle => 'Enjoying the game?';

  @override
  String get reviewPromptBody =>
      'A 5-star rating ⭐ helps us a ton and takes just a few seconds';

  @override
  String get reviewPromptRateButton => 'Rate us 5 stars';

  @override
  String get reviewPromptMaybeLaterButton => 'Maybe later';

  @override
  String get presenceAdminModeDuel => 'Duel';

  @override
  String get presenceAdminModeSuperDuel => 'Duel series';

  @override
  String get presenceAdminModeRace => 'Race';

  @override
  String get presenceAdminTitle => 'Online players tracking';

  @override
  String get presenceAdminTotalLabel => 'Total';

  @override
  String get presenceAdminSeriesLabel => 'Series';

  @override
  String presenceAdminLastRefreshLabel(int seconds) {
    return 'Updated $seconds seconds ago · auto-refreshes every 10 seconds';
  }

  @override
  String get presenceAdminEmptyMessage =>
      'No one is online right now (or there\'s no network) ⚠️ Note: players already inside an active duel game (not in the lobby) aren\'t counted - a known limitation, see the note in presence_service.dart';

  @override
  String presenceAdminSecondsAgo(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String get previewUsername => 'Guest123';

  @override
  String get previewMedalsCount => '0 / 15 medals';

  @override
  String get previewContinueBannerLabel => 'Continue where you left off';

  @override
  String previewStageLabel(int n) {
    return 'Stage $n';
  }

  @override
  String get previewCompletedLabel => 'Completed';

  @override
  String get previewContinuePlayingButton => 'Continue playing';

  @override
  String get previewDailyChallengeTitle => 'Daily challenge';

  @override
  String get previewDailyChallengeSubtitle => '6 logos · special reward';

  @override
  String get previewConnectedCount => '8 online';

  @override
  String get previewRandomChallengeSubtitle =>
      'Random logo · keeps your streak';

  @override
  String get updateNotesLoadError =>
      'We couldn\'t load the updates - try again later';

  @override
  String get updateNotesTitle => 'What\'s new in the game';

  @override
  String get updateNotesEmptyMessage => 'No update notes yet - check back soon';

  @override
  String get updateRequiredTitle => 'A new version is available';

  @override
  String get updateRequiredUpdateNowButton => 'Update now';

  @override
  String updateRequiredVersionInfo(String current, String min) {
    return 'Version $current · requires $min';
  }

  @override
  String get whatsNewDuelSeriesTitle => 'Duel series';

  @override
  String get whatsNewDuelSeriesSubtitle =>
      'New duel: best of 3! Same opponent, up to 3 rounds, with a fat coin bonus for winning the series';

  @override
  String get whatsNewNewLevelsTitle => 'New levels added';

  @override
  String get whatsNewNewLevelsSubtitle =>
      'More stages and more logos to identify are waiting for you on the levels screen';

  @override
  String get whatsNewDifficultyTitle => 'Difficulty levels 1-5';

  @override
  String get whatsNewDifficultySubtitle =>
      'Every world gets a difficulty rating — and the higher the duel stake, the higher the logo difficulty too';

  @override
  String get whatsNewReferralBonusTitle => 'Bigger friend invite bonus';

  @override
  String get whatsNewReferralBonusSubtitle =>
      'Now you get 75 coins (instead of 30) for every friend who joins with your code';

  @override
  String whatsNewVersionBadge(String version) {
    return '✨ Version $version';
  }

  @override
  String get whatsNewHeaderTitle => 'Updated just for you!';

  @override
  String whatsNewHeaderSubtitle(String version) {
    return 'What\'s new in version $version?';
  }

  @override
  String get whatsNewNewBadge => 'New';

  @override
  String get whatsNewGetStartedButton => 'Let\'s get started';

  @override
  String get settingsWhatsNewLink => 'What\'s new';

  @override
  String get settingsReportIssueLink => 'Report an issue';

  @override
  String get settingsPrivacyLink => 'Privacy';

  @override
  String get settingsRateUsLink => 'Rate us';

  @override
  String get settingsDeleteUserLink => 'Delete user';

  @override
  String settingsVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsChangeNameButton => 'Change name';

  @override
  String get settingsLogosStatLabel => 'Logos';

  @override
  String get settingsWinsStatLabel => 'Wins';

  @override
  String get settingsVibrationLabel => 'Vibration';

  @override
  String get settingsNotificationsLabel => 'Notifications';

  @override
  String get settingsInviteFriendsLabel => 'Invite friends';

  @override
  String get settingsHowToPlayLabel => 'How to play?';

  @override
  String get settingsHowToPlayBody =>
      'In every stage, a blurred or cropped logo appears. Type the exact name using the keyboard below.\n\n🗺️ Levels and stages: you progress by categories - each solve unlocks the next stage. A successful solve earns 10 XP and 2 coins (every letter hint subtracts 1 XP, and solving the whole word with a hint gives only 5 XP).\n\n🎲 Random challenge: a random logo from all categories, no repeats! Every correct solve increases your streak 🔥 and adds an XP bonus (up to +5). The streak is kept even when you leave - and resets only if you get the word wrong.\n\n⚔️ 1-on-1 duel: two players get the same logos, whoever finishes first wins. Costs energy (regenerates over time).\n\n💡 Hints: revealing a letter - 15 coins, solving the word - 60 coins. Out of coins? You can watch an ad and get a free hint!';

  @override
  String get settingsLinkAccountLabel => 'Link account';

  @override
  String get settingsLinkAccountSub =>
      'Keeps your progress even if you switch devices';

  @override
  String settingsLinkedAccountLabel(String names) {
    return 'Linked - $names';
  }

  @override
  String get settingsSignOutConfirmTitle => 'Sign out of your account?';

  @override
  String get settingsSignOutConfirmBody =>
      'Your current progress will stay on this device as usual. You can sign in to the same account again anytime.';

  @override
  String get settingsSignOutButton => 'Sign out';

  @override
  String get settingsSignedOutMessage => 'Signed out of your account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete the user?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'All your progress (coins, XP, stages, streaks) will be permanently deleted and can\'t be restored. This action is final.';

  @override
  String get settingsDeletePermanentlyButton => 'Delete permanently';

  @override
  String get settingsAccountDeletedMessage =>
      'The user was deleted. Close and reopen the app to start over.';

  @override
  String get settingsDeleteFailedMessage => 'Deletion failed, try again later';

  @override
  String get settingsSupportEmailSubject => 'Bug report - Guess the Logo!';

  @override
  String settingsSupportEmailBody(String username) {
    return 'Hi!\n\nDescription of the issue:\n\n\nWhat I was doing when it happened:\n\n\n---\nMy name in the game: $username';
  }

  @override
  String settingsNoMailAppMessage(String email) {
    return 'No mail app found. You can write to us manually at $email';
  }

  @override
  String get settingsChangeNameDialogTitle => 'Change name';

  @override
  String get settingsSaveButton => 'Save';

  @override
  String get settingsTabGame => 'Game';

  @override
  String get settingsTabSound => 'Sound';

  @override
  String get settingsTabAccount => 'Account';

  @override
  String get settingsTabHelp => 'Help';

  @override
  String get settingsTabHintGame => 'How the game feels to you';

  @override
  String get settingsTabHintSound => 'Music, effects and vibration';

  @override
  String get settingsTabHintNotifications => 'What we\'ll update you about';

  @override
  String get settingsTabHintAccount => 'Privacy, purchases and connection';

  @override
  String get settingsTabHintHelp => 'Support and more';

  @override
  String get settingsGameLanguageLabel => 'Game language';

  @override
  String get settingsMusicLabel => 'Music';

  @override
  String get settingsEffectsLabel => 'Effects';

  @override
  String get settingsHintConfirmLabel => 'Confirm before buying a hint';

  @override
  String get settingsHintConfirmSub => 'So you don\'t spend coins by accident';

  @override
  String get settingsLevelTimerLabel => 'Show a timer during levels';

  @override
  String get settingsAutoAdvanceLabel => 'Auto-advance to the next logo';

  @override
  String get settingsAutoAdvanceSub => 'You can still tap through any time';

  @override
  String get settingsVibrationSub => 'On correct and wrong answers';

  @override
  String get settingsNotifAllLabel => 'All notifications';

  @override
  String get settingsNotifTournamentLabel => 'Tournament updates';

  @override
  String get settingsNotifDailyLabel => 'Daily reminders';

  @override
  String get settingsNotifEnergyLabel => 'Energy is full';

  @override
  String get settingsMyAchievementsLabel => 'My achievements';

  @override
  String get settingsRankBeginner => 'Beginner';

  @override
  String get settingsRankIntermediate => 'Intermediate';

  @override
  String get settingsRankVeteran => 'Veteran';

  @override
  String get settingsRankChampion => 'Champion';

  @override
  String get settingsInviteCodeLabel => 'Your code:';

  @override
  String get settingsFollowUsLabel => 'Follow us';

  @override
  String settingsFollowRewardLabel(int coins) {
    return '+$coins for each';
  }

  @override
  String get settingsRemoveAdsLabel => 'Remove ads';

  @override
  String get settingsRemoveAdsOwnedLabel => 'Active';

  @override
  String get settingsContactUsLabel => 'Contact us';

  @override
  String get settingsGeneralContactSubject =>
      'General inquiry - Guess the Logo!';

  @override
  String settingsGeneralContactBody(String username) {
    return 'Hi!\n\n\n---\nMy in-game name: $username';
  }

  @override
  String get mainMenuTourPlayButtonTitle => 'Here\'s where you start playing';

  @override
  String get mainMenuTourPlayButtonBody =>
      'Tap the \"Play\" button to see every mode - levels, word search, random, daily challenge, and real-time play against others.';

  @override
  String get mainMenuTourLevelsCardTitle => 'Now let\'s start playing';

  @override
  String get mainMenuTourLevelsCardBody =>
      'Tap \"Levels\" to pick a world and solve your first logo!';

  @override
  String get mainMenuTournamentHeroLiveBadge => 'Daily Tournament · Live now';

  @override
  String get mainMenuTournamentHeroPotLabel => 'The Pot';

  @override
  String mainMenuTournamentHeroParticipants(int count) {
    return '$count participants';
  }

  @override
  String mainMenuTournamentHeroJoinButton(int fee) {
    return 'Join for $fee 🪙';
  }

  @override
  String get mainMenuDailyChallengeMiniTitle => 'Daily Challenge';

  @override
  String get mainMenuFriendsMiniTitle => 'Online';

  @override
  String get mainMenuTopPerformersTitle => 'Today\'s Leaders';

  @override
  String get mainMenuTopPerformersEmpty =>
      'No one has played today\'s tournament yet - be the first!';

  @override
  String get mainMenuModesSheetTitle => 'How do you want to play today?';

  @override
  String get mainMenuModesSheetSoloSection => 'Solo';

  @override
  String get mainMenuModesTafzoretTitle => 'Word Search';

  @override
  String mainMenuModesTafzoretNote(int count) {
    return '$count worlds';
  }

  @override
  String get mainMenuModesLevelsTitle => 'Levels';

  @override
  String mainMenuModesLevelsNote(int level) {
    return 'Level $level';
  }

  @override
  String get mainMenuBottomNavTournaments => 'Tournaments';

  @override
  String get mainMenuTournamentChooserTitle => 'Choose a tournament';

  @override
  String get mainMenuTournamentChooserDailyTitle => '3-Day Challenge';

  @override
  String mainMenuTournamentChooserDailySubtitle(int fee) {
    return 'Join for $fee coins for a 3-day event · the pot already starts at 100';
  }

  @override
  String get mainMenuTournamentChooserScheduledTitle => 'Scheduled Tournament';

  @override
  String mainMenuTournamentChooserScheduledSubtitle(int fee, int count) {
    return 'Every day at 20:00 · join for $fee coins · $count logos';
  }

  @override
  String get mainMenuStoriesInviteLabel => 'Invite';

  @override
  String get mainMenuFriendOnlineStatus => 'Online';

  @override
  String get mainMenuFriendOfflineStatus => 'Offline';

  @override
  String get mainMenuHappeningNowTitle => 'Happening now';

  @override
  String mainMenuTournamentRowSubtitle(int pot, int count) {
    return '$pot coin pot · $count participants';
  }

  @override
  String get mainMenuEventRowTimeLeftLabel => 'left';

  @override
  String get mainMenuShopBonusTitle => 'Tournament win bonus';

  @override
  String get mainMenuShopBonusSubtitle => '1.25x coins on every shop purchase';

  @override
  String get mainMenuContinueButton => 'Continue';

  @override
  String get mainMenuTodayRankingTitle => 'Your ranking today';

  @override
  String get mainMenuTodayRankingYouLabel => 'You';

  @override
  String mainMenuTodayRankingAheadMessage(int xp, String name) {
    return '▲ $xp more XP and you\'ll pass $name';
  }

  @override
  String get mainMenuTodayRankingEmpty => 'Play to appear on the leaderboard!';

  @override
  String get mainMenuNoFriendsTitle => 'You don\'t have friends yet';

  @override
  String get mainMenuNoFriendsSubtitle =>
      'Invite friends and compete together!';

  @override
  String get mainMenuShopQuickLinkSubtitle => 'Coins, energy and more';

  @override
  String get mainMenuHomeTitle => 'Guess the Logo';

  @override
  String get mainMenuHomeTagline => 'How many logos do you know?';

  @override
  String get mainMenuModesSheetTitleShort => 'Choose a mode';

  @override
  String get mainMenuModesSheetSubtitle => 'Pick a mode and get going';

  @override
  String mainMenuTournamentTileSubtitlePrefix(int pot) {
    return '$pot pot ·';
  }

  @override
  String get mainMenuShopTileBonusActive => 'Bonus active!';

  @override
  String mainMenuLevelProgressTitle(int world, int sub) {
    return 'Level $world · Stage $sub';
  }

  @override
  String get mainMenuLevelProgressSubtitle =>
      'Every logo brings you closer to the next world';

  @override
  String mainMenuStreakBadge(int days) {
    return '🔥 $days';
  }
}
