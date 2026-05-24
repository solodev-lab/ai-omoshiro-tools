import 'dart:math';
import '../../utils/moon_phase.dart';

/// 月齢 (端末ローカル) を 3 日ごと 10 区分に分け、その区分の月相に沿った
/// 癒しメッセージを 1 つ返す。
///
/// 区分: 0=新月期 / 1=三日月 / 2=上弦 / 3=盈月 / 4=満月前 / 5=満月 /
///       6=欠け始め / 7=下弦 / 8=暁月 / 9=新月前。
///
/// 選択は「その日の日付」をシードにするため、同じ日のあいだは同じ文面で
/// 安定し (再描画で点滅しない)、日が変わると別の文面に切り替わる。
///
/// 文面の方針 (オーナー承認): 温かめの敬語 / 時間帯を断定しない (昼に見る人がいる
/// ため「夜」「空は暗い」等は使わない) / 分かりにくい比喩を避ける / どんな状態の
/// 人も否定しない / 突き放さず、難しさを認めてから希望を渡す。
String moonHealingMessage(DateTime now, {required bool isJP}) {
  final seg = (MoonPhase.getPhaseInt(now) ~/ 3).clamp(0, 9);
  final l = now.toLocal();
  final daySeed = l.year * 10000 + l.month * 100 + l.day;
  final list = (isJP ? _healingJP : _healingEN)[seg];
  return list[Random(daySeed).nextInt(list.length)];
}

const List<List<String>> _healingJP = [
  // 0 — 新月期 (始まり・意図・内省のはじまり)
  [
    '新しい月がはじまりました。今日は願いを、そっと心に置いてみましょう。',
    '普段は表に出しにくいものですね。あなたの中にある本当の望みを、そっと見つめてあげましょう。',
    '決めるのも、決めないのも、あなたの自由です。新しい月がはじまれば、あなたの道も自然と見えてきますよ。',
    'うまく望めなくても大丈夫。あなたの本当の願いは、これから少しずつ見えてきます。',
    '今はまだ、答えが出なくてもいいのです。問いを持っているだけで、もう始まっています。',
    '小さな願いほど、大切に育っていきます。今日ふと心に浮かんだことを、覚えておいてください。',
    '満たそうと急がなくて大丈夫。心に少し余白をつくると、本当の望みが顔を出します。',
    'はじまりのときは、誰でも手探りです。わからないままで、進んでいいのです。',
    '自分の望みがわからない——それでも大丈夫。わからないと知っていること自体が、はじめの一歩です。',
    '新しいはじまりに、ひとつ深呼吸を。あなたのペースで、ここから始めましょう。',
  ],
  // 1 — 三日月 (芽吹き・小さな一歩・はじめたばかり)
  [
    '月が少しずつ、ふくらみはじめました。あなたの一歩も、もう動き出していますよ。',
    'はじめたばかりのことは、うまくいかなくて当たり前です。どうか自分を責めないでください。',
    '今日できる小さなことを、ひとつだけ。それだけで、ちゃんと前に進んでいます。',
    'まだ手応えがなくても大丈夫。見えないところで、あなたの根はのびています。',
    '大きく変わらなくていいのです。少しずつでも、あなたは確かに育っています。',
    '迷いながらでも、進んでいいのです。細い道も、歩くうちに広がっていきます。',
    '三日月のように、いまは細くても大丈夫。これから少しずつ、満ちていきます。',
    'うまく踏み出せない日も、立ち止まっているわけではありません。それも前進です。',
    '小さな勇気を、ひとつ持てた自分を、どうか認めてあげてください。',
    '焦らなくて大丈夫。月も、急がずにゆっくりと満ちていきます。',
  ],
  // 2 — 上弦 (成長・行動・決断・前進)
  [
    '月は半分まで満ちました。あなたも、ここまでよく歩いてきましたね。',
    '迷いがあっても、選んでみていいのです。動き出した先に、道はできていきます。',
    '半分の月は、光と影をどちらも持っています。あなたのどちらの面も、大切なものです。',
    '完璧でなくて大丈夫。立ち止まったり、進んだりしながら、少しずつ整えていけばいいのです。',
    'やってみたいことがあるなら、その気持ちを大事にしてください。',
    '一歩踏み出すのが、こわい日もありますね。自分の力を信じてね。いつも私たちは応援していますよ。',
    '育っていく月のように、あなたの力も、いま伸びている途中です。',
    '半分の光でも、足もとを照らすには十分です。あなたのその歩みを信じて。',
    'うまく決められなくても、それもひとつの答えです。焦らずいきましょう。',
    '上り坂の途中で、息が切れたら休んでいいのです。それから、新しい歩みが必ずはじまります。',
  ],
  // 3 — 盈月 (積み重ね・粘り・あと少し)
  [
    '月は満ちる手前まで来ました。あなたの積み重ねも、実りに近づいています。',
    'ここまで続けてこられた自分を、どうか誇ってください。',
    'うまくいかない日があっても、それも満ちていく途中の、大切な一歩です。',
    'もう半分以上、来ています。これまでを振り返ると、景色が変わって見えるはずです。',
    '「あと少し」と感じるときほど、力を抜いて、ひとつ深呼吸を。',
    '仕上げに近づく今は、細かなところにも、やさしく目を向けてみましょう。',
    '焦らず、あなたのペースのままで大丈夫です。私たちはあなたを見守っています。',
    'ふくらんでいく月のように、あなたの想いも、しっかり育っています。',
    '結果がまだ見えなくても大丈夫。続けてきたことは、ちゃんと積もっています。',
    'もうすぐ満ちる月。ここまで来たあなたを、まずは労ってあげてください。',
  ],
  // 4 — 満月前 (高まり・期待・満ちていく)
  [
    '満月が近づいています。気持ちが高ぶるときは、ひとつ深呼吸をしてみましょう。',
    'もうすぐ満ちる月。あなたの努力も、まもなく形になろうとしています。',
    'そわそわと落ち着かない感じも、満ちていく途中の、自然な揺れです。',
    '高まる気持ちは、あなたが満ちていく証。そのままで大丈夫です。',
    '力が湧いてくるときほど、無理をしすぎないようにしてくださいね。',
    'もう少しで満月です。ここまでの道のりを、静かに思い返してみましょう。',
    '期待がふくらむのは、悪いことではありません。どうか、その高まりを味わって。',
    '満ちる直前の月は、いちばん希望に満ちています。いまのあなたも、きっと同じです。',
    'うまく気持ちが乗らない日も大丈夫。満ちる前は、誰でも揺れるものです。',
    'まもなく満月。今日はただ、自分の心を満たすことを考えてみましょう。',
  ],
  // 5 — 満月 (結実・感謝・受け取る・解放)
  [
    '月が満ちました。あなたも今、十分にがんばってきましたね。',
    '受け取る時間です。差し出されたものを、遠慮なく受け取ってください。',
    '満月は、手放しの合図でもあります。重たく感じるものは、そっと月にあずけて。',
    'これまでのすべてに、まあるい「ありがとう」を。',
    'がんばってきた自分を、今日はやさしく抱きしめてあげてください。',
    '満ちた月のように、あなたの心も、まるくやわらかでありますように。',
    '実ったものを、急いで何かにしなくていいのです。まずは静かに味わって。',
    '満月の光は、隠していた気持ちも照らします。ありのままのあなたで大丈夫。',
    '満ちたら、あとはゆるめるだけ。少し、肩の力を抜いてみましょう。',
    'うまく喜べない日もありますね。それでも、あなたはここまで満ちてきました。',
  ],
  // 6 — 欠け始め (ゆるめる・振り返る・分かち合う)
  [
    '月が少しずつ欠けはじめます。手放していくことも、やさしさのひとつです。',
    '満ちたあとは、ゆるめていい時間です。張りつめていた肩を、そっと下ろして。',
    '受け取ったものを、まわりとそっと分け合ってみるのもいいですね。',
    '振り返ってみると、ちゃんと進んできた自分に気づけます。',
    'がんばりすぎた日は、月にならって、少し力を抜いてみましょう。',
    '立ち止まる時間も、進むことと同じくらい大切です。',
    '欠けていく月は、引き算のうつくしさ。手放すほど、心は軽くなります。',
    '何もしない時間を、自分に少しだけ許してあげてください。',
    'うまく休めない人ほど、今日は意識して、ひと息ついてみましょう。',
    '月が静かにほどけていくように、あなたも少しずつ、ゆるめていって大丈夫です。',
  ],
  // 7 — 下弦 (手放す・整理・選び直す)
  [
    '月は半分まで欠けました。いらなくなったものを、そっと手放す時間です。',
    '手放すことは、失うことではありません。次のための余白を、つくることです。',
    '心の引き出しを、今日はひとつだけ、片づけてみませんか。',
    '抱えすぎていたなら、ひとつだけでも、下ろしてみていいのです。',
    '半分の月の静けさのなかで、本当に大切なものが見えてきます。',
    '何かを終わらせることも、新しい始まりの準備になります。',
    '欠けていく月のように、肩の荷も、少しずつ軽くしていきましょう。',
    'うまく手放せなくても大丈夫。手放せない自分も、責めないでください。',
    'いまの自分に問いかけてみる。あなたの声はあなたにしか聞けません。あなたの声を大切にしてあげてね。',
    '手のひらをひらけば、次の何かを受け取る余白が生まれます。',
  ],
  // 8 — 暁月 (浄化・休息・許し)
  [
    '月がほそく、やさしくなりました。今は、休んでいい時間です。',
    '何も進まないと感じる日があっても大丈夫。私たちがあなたに代わってあなたの幸せを創っています。',
    'よくここまで歩いてきましたね。今日は、自分を許してあげてください。',
    '疲れたら、立ち止まって大丈夫。月も、欠けながら静かに力を蓄えています。',
    '細くなる月のように、あなたも今は、ゆっくりで大丈夫です。',
    '心にたまったものを、すこしずつ、手放していきましょう。',
    '自分にやさしくする練習を、今日から少しだけ始めてみませんか。',
    'がんばった分だけ、休んでいいのです。どうか、ご自分を労って。',
    'うまく休めない人ほど、肩の力を、ふっと抜いてみてください。',
    'もうすぐ新月です。今は深く息を吐いて、ゆだねてみましょう。',
  ],
  // 9 — 新月前 (静寂・内省・余白・次への準備)
  [
    'もうすぐ新しい月がはじまります。今は何も足さず、空っぽでいてもいい時間です。',
    '余白の時間です。次の願いが芽生えるまで、そっと待ってみましょう。',
    'すべてを手放したあとに、新しい何かが、そっとやってきます。',
    '月が見えなくなっても、あなたの光は消えていません。',
    '自分の内側を、静かに見つめてみる時間です。本当の気持ちに、耳を澄ませて。',
    'うまく前を向けない日も大丈夫。後ろを向きたい気持ちが今の流れかもしれません。あなたはいつも素晴らしい事を行っていますよ。',
    '今は、ひと休みの時間。次の一歩のために、静けさを味わいましょう。',
    'もうすぐ新月。これまでの月に、そっと「ありがとう」を伝えてみましょう。',
    '空っぽになることを、こわがらなくて大丈夫。それは、満ちる前の余白です。',
    '何も決まっていなくても大丈夫。新しい月が、また道を照らしてくれます。',
  ],
];

const List<List<String>> _healingEN = [
  // 0 — New Moon (begin, intention, looking inward)
  [
    'A new moon begins. Today, gently rest a wish in your heart.',
    "These feelings are hard to show, aren't they? Take a quiet look at the true wish inside you.",
    'To decide, or not — both are yours to choose. As this new cycle begins, your path will come into view on its own.',
    "It's okay if you can't wish clearly yet. Your true longing will come into view, little by little.",
    "You don't need an answer yet. Simply holding the question means you've already begun.",
    'The smallest wishes grow the most tenderly. Hold on to whatever crossed your mind today.',
    'No need to hurry to fill yourself. Make a little space, and your true wish will show its face.',
    "At every beginning, we are all feeling our way. It's okay to go on, even unsure.",
    "You don't know what you wish for — and that's okay. Knowing that you don't know is itself the first step.",
    'To this new beginning, one deep breath. Begin here, at your own pace.',
  ],
  // 1 — Crescent (sprouting, small steps, just begun)
  [
    'The moon has begun to fill, little by little. Your first step is already in motion.',
    "When something is new, it's natural for it not to go smoothly. Please don't blame yourself.",
    'Just one small thing you can do today. That alone is real progress.',
    "Even if you feel nothing yet, your roots are growing where you can't see.",
    "You don't have to change in big ways. Little by little, you really are growing.",
    "It's okay to move while unsure. Narrow paths widen as you walk them.",
    "Like the crescent, it's okay to be thin for now. From here, you'll fill little by little.",
    "Even on days you can't step forward, you aren't standing still. That, too, is progress.",
    'Please acknowledge the you who found just a little courage today.',
    'No need to rush. The moon, too, fills slowly, without hurry.',
  ],
  // 2 — First Quarter (growth, action, choice)
  [
    "The moon has filled to half. You've walked far to get here.",
    "Even unsure, it's okay to choose. The path forms ahead of you once you move.",
    'The half-moon holds both light and shadow. Both sides of you are precious.',
    "You don't have to be perfect. Pausing, moving on — either way, you can set things right little by little.",
    "If there's something you want to try, treasure that feeling.",
    "Some days, stepping forward feels frightening. Believe in your own strength. We are always cheering you on.",
    'Like the growing moon, your strength is still rising.',
    "Even half-light is enough to light your feet. Trust the steps you're taking.",
    "If you can't quite decide, that's an answer too. Let's go gently.",
    "If you run out of breath partway up the hill, it's okay to rest. After that, a new stride will surely begin.",
  ],
  // 3 — Waxing Gibbous (building, persistence, almost there)
  [
    'The moon has nearly filled. Your efforts, too, are nearing their harvest.',
    'Please be proud of yourself for keeping on this far.',
    "Even days that don't go well are precious steps on the way to full.",
    "You're more than halfway. Look back, and the view has changed.",
    'The more you feel "almost there," the more it helps to ease up and breathe.',
    'As you near the finish, turn a gentle eye to the small details, too.',
    "No need to rush — your own pace is just fine. We are watching over you.",
    'Like the swelling moon, your hopes are growing strong.',
    "Even if you can't see results yet, what you've continued is quietly adding up.",
    'The moon will soon be full. First, take a moment to thank yourself.',
  ],
  // 4 — Before Full Moon (rising, anticipation)
  [
    'The full moon draws near. When your heart races, try one deep breath.',
    'Soon the moon is full. Your effort is about to take shape.',
    "That restless, unsettled feeling is a natural sway on the way to full.",
    "Rising feelings are proof that you're filling. You're fine just as you are.",
    'The more energy wells up, the more gently you should treat yourself.',
    "Almost full. Quietly look back on the road you've traveled.",
    "It's not a bad thing for hope to swell. Please savor that rising feeling.",
    'The moon just before full is the most full of hope. So, surely, are you.',
    "Off days happen. Before fullness, everyone sways a little.",
    'Soon, the full moon. Today, simply think of filling your own heart.',
  ],
  // 5 — Full Moon (harvest, gratitude, receiving, release)
  [
    'The moon is full. You, too, have truly given your all.',
    "A time to receive. Take in what's offered to you, freely.",
    "The full moon is also a sign of release. Hand what feels heavy to the moon.",
    'To all that has come before, a round and full "thank you."',
    'Today, gently embrace the you who has tried so hard.',
    'Like the full moon, may your heart be round and soft.',
    "You don't have to rush what's ripened into anything. First, just savor it.",
    "Full moonlight reveals even hidden feelings. You're fine just as you are.",
    "Once full, all that's left is to soften. Ease your shoulders a little.",
    'Some days you can\'t quite rejoice. Even so, you have filled this far.',
  ],
  // 6 — Waning Gibbous (loosen, reflect, share)
  [
    'The moon begins to wane. Letting go, too, is a kind of tenderness.',
    "After fullness, it's okay to loosen. Lower the shoulders you've held so tight.",
    "It can be lovely to share what you've received with those around you.",
    "Look back, and you'll notice how far you've truly come.",
    "On days you've tried too hard, ease off, just like the moon.",
    'Time spent pausing matters as much as time spent moving.',
    'The waning moon is the beauty of subtraction. Lighter with each release.',
    'Allow yourself a little time to do nothing at all.',
    'The harder it is for you to rest, the more worth it to pause for one breath today.',
    'As the moon quietly unwinds, it\'s okay to loosen, little by little.',
  ],
  // 7 — Last Quarter (let go, sort, re-choose)
  [
    'The moon has waned to half. A time to gently let go of what you no longer need.',
    "Letting go isn't losing. It's making space for what comes next.",
    'Why not tidy just one drawer of your heart today?',
    "If you've been carrying too much, it's okay to set down even one thing.",
    "In the half-moon's stillness, what truly matters comes into view.",
    'Ending something, too, is preparation for a new beginning.',
    'Like the waning moon, let your burdens grow lighter, little by little.',
    "It's okay if you can't let go. Please don't blame the you who holds on.",
    "Ask yourself how you really are. Only you can hear your own voice. Please treasure that voice of yours.",
    "Open your hands, and space appears to receive what's next.",
  ],
  // 8 — Waning Crescent (cleanse, rest, forgive)
  [
    'The moon has grown thin and gentle. Now is a time to rest.',
    "It's okay to have days when nothing seems to move forward. We are creating your happiness on your behalf.",
    "You've walked so far. Today, please forgive yourself.",
    "If you're tired, it's okay to stop. The moon, too, quietly gathers strength as it wanes.",
    "Like the thinning moon, it's okay to go slowly now.",
    "Let what's gathered in your heart be released, little by little.",
    'Why not begin, just a little, the practice of being kind to yourself today?',
    "You may rest as much as you've tried. Please, be tender with yourself.",
    'The harder it is for you to rest, the more gently let your shoulders drop.',
    'Soon, the new moon. Breathe out deeply now, and let yourself surrender.',
  ],
  // 9 — Before New Moon (stillness, inward, space, preparing)
  [
    "A new moon will soon begin. For now, it's okay to add nothing and simply be empty.",
    'A time of space. Wait gently, until the next wish begins to sprout.',
    "After you've released everything, something new quietly arrives.",
    "Even when the moon can't be seen, your light has not gone out.",
    'A time to look quietly within. Listen closely to your true feelings.',
    "It's okay on days you can't face forward. The wish to look back may be the flow of this moment. You are always doing something wonderful.",
    'This is a moment of rest. Savor the stillness before your next step.',
    "Soon, the new moon. Try gently thanking the moon that has passed.",
    "Don't be afraid of becoming empty. It's the space before filling.",
    "It's okay if nothing is decided yet. A new moon will light your path again.",
  ],
];
