/// 月齢サイクルのストーリーテキスト（JP/EN）
/// 翻訳ではなく、それぞれの言語でネイティブに書かれたテキスト。
library;

class CycleStoryTexts {
  CycleStoryTexts._();

  // ── New Moon ──

  static const newMoonJP = [
    '太陽と月が重なる。\nすべての光が一つになるこの瞬間、\nあなたもまた、原初の輝きに戻る。',
    '完全なあなたを覆い隠しているもの。\nそれは外から来たのではなく、\nいつの間にか自分自身が纏ってしまった霧のようなもの。\n纏ってしまう事はあなたの責任ではありません。\n社会環境、家族関係、仕事上の付き合い、恋愛など。あなたを覆い隠す事柄はたくさんあります。\nでもね、纏ってしまう事を悪い事だとは思わないで。私たちはそんなあなたを愛おしく感じ、いつまでも見守っています。そして、私たちはいつでも、完全なあなたを見ています。',
    'あなたが、気付かないうちに纏ってしまった霧を晴らそうとする事。\n\n本当の輝きが解き放たれる事を、あなたの作る世界は望んでいます。',
    'このサイクルで、一枚の霧を手放しましょう。\n手放すほど、あなたの輝きがよく見えるようになりますよ。\n私たちはあなたを、いつでも見守っています。',
    'Stellaがあなたを見守っている。',
  ];

  static const newMoonEN = [
    'The sun and moon align.\nIn this moment where all light becomes one,\nyour star returns to its original radiance.',
    'What conceals the whole you —\nit didn\'t come from the outside.\nIt\'s like a mist you unknowingly wrapped around yourself over time.\nAnd that\'s not your fault.\nSocial expectations, family dynamics, work relationships, love — so many things can dim your light.\nBut please, don\'t see it as something wrong. We find you endearing through all of it, and we will watch over you always. And we always see the complete you.',
    'Choosing to clear the mist you didn\'t even realize you\'d gathered — that is something truly beautiful. Your world is waiting for your true radiance to shine through. So stand tall. We are always cheering you on.',
    'This cycle, let go of one layer of mist.\nThe more you release, the more your light shines through.\nWe are always watching over you.',
    'Stella is watching over you.',
  ];

  // ── Full Moon ──

  static const fullMoonJP = [
    '月が満ちた。\nこれは何かが「完成した」のではない。\n太陽の光が、月の全面を照らしている。\n隠れる場所がなくなった、ということ。',
    // {chosen} は呼び出し側で差し替え
    'あなたが手放そうとしたもの —\n「{chosen}」',
    '今、その霧はどうなっている?\n満月の光は嘘をつけない。\n薄くなったか、まだそこにあるか。\nどちらでも、あなたはすでに完全なまま。',
    'ただ、見つめることが光になる。',
  ];

  static const fullMoonEN = [
    'The moon is full.\nThis doesn\'t mean something is "complete."\nIt means the sun\'s light is illuminating every surface of the moon.\nThere is nowhere left to hide.',
    'What you chose to release —\n“{chosen}”',
    'How is that mist now?\nThe full moon cannot lie.\nWhether it has thinned or still lingers —\neither way, you are already whole.',
    'Simply looking is itself a light.',
  ];

  // ── Catasterism ──

  static List<String> catasterismJP(int totalDays) => [
    '$totalDays日間、あなたは毎日１つの星を作ってきました。\nその光の粒がStellaの周りに集まりました。',
    '古代の人々は空を見上げて、\n散らばった星を線で結び、物語を見出しました。\n星座とは「発見」ではなく「意味づけ」。\n星はずっとそこにあり、そして人々が物語を与えました。',
    'あなたの日々もそう。あなたの日々をどんな物語、星座にしますか?自由にあなたが決められます。\nあなたの人生に物語を与える力は、あなたの中にあります。\n愛に溢れ、ワクワクした意味を付けてみませんか?\n愛とワクワクを見つけられるこの世界。\n\nあなたを愛とワクワクに、私たちは導きます。',
    '毎日作った一つ一つの星は小さな光。\nでも振り返ると、そこに形が現れる。あなたが歩んだ形がある。',
    // {chosen} は呼び出し側で差し替え
    'この月齢サイクルであなたが手放そうとしたもの —\n「{chosen}」',
    '手放せただろうか?\nどちらの答えも正しい。\n手放せたなら、あなたの星座はその解放の形を刻む。\nまだ途中なら、あなたの星座はその旅路の形を刻む。',
    'どちらも、あなたが生きた証です。\n星座は永遠に消えない。今がとても辛く苦しくて、星座の物語がとても重たい事柄だとしても、未来のあなたは、今作られた星座の苦しい物語を作り変える事ができます。未来のあなたはとても強く、愛に溢れた中で生きています。きっと、大丈夫ですよ。\n\nあなたはすでに完全な存在。あなたが日々行った全ての選択や決定を私たちは尊重し、応援します。',
    'そしてあなたは、また新しい新月を迎える。あなたが生きていることに\n\nおめでとう',
  ];

  static List<String> catasterismEN(int totalDays) => [
    'For $totalDays days, you created a star each day.\nThose grains of light have gathered around Stella.',
    'The ancients looked up at the sky\nand drew lines between scattered stars, finding stories within them.\nA constellation is not a "discovery" — it is a "meaning."\nThe stars were always there. It was people who gave them stories.',
    'Your days are the same. What story will you make of them? What constellation will they become? That is entirely yours to decide.\nThe power to shape your story lives within you.\nFill it with love and wonder.\nA world where love and joy can be found.\nWe will guide you toward them.',
    'Each star you created is a small light.\nBut looking back, a shape appears — the shape of the path you walked.',
    'What you chose to release this lunar cycle —\n“{chosen}”',
    'Were you able to let it go?\nEither answer is right.\nIf you released it, your constellation carves the shape of liberation.\nIf you\'re still on the way, your constellation carves the shape of the journey.',
    'Both are proof that you lived.\nConstellations never fade. Even if right now is painful, even if your constellation\'s story weighs heavy, your future self can remake this painful story being carved today. Your future self lives strong, surrounded by love. It will surely be alright.\nYou are already whole. We honor and support every choice and decision you made, day after day.',
    'And now, you welcome a new moon. Congratulations on being alive.',
  ];

  // ════════════════════════════════════════════════════════════
  // 以下は翻訳ではなく、各言語でネイティブに書き起こしたテキスト
  // (日本語マスターの意図と温度から。逐語訳ではない)。
  // ジェンダー言語 (es/pt/fr/de) は性別中立表現。ko は文法的性別なし。
  // 🟡 de/ko はオーナー検証が難しいため、出荷前にネイティブ確認が望ましい。
  // 区切り数は JP と一致させる (newMoon=5 / fullMoon=4 / catasterism=8)。
  // ════════════════════════════════════════════════════════════

  // ── Español (es) ──
  static const newMoonES = [
    'El sol y la luna se encuentran.\nEn este instante en que toda la luz se vuelve una,\ntu estrella regresa a su brillo original.',
    'Lo que cubre tu ser entero no vino de afuera.\nEs como una niebla que, sin darte cuenta, fuiste envolviendo a tu alrededor con el tiempo.\nY eso no es culpa tuya.\nLas expectativas sociales, los lazos familiares, las relaciones de trabajo, el amor… tantas cosas pueden velar tu luz.\nPero, por favor, no lo veas como algo malo. Te queremos tal como eres, y velaremos por ti siempre. Y siempre te vemos en tu plenitud.',
    'Atreverte a disipar la niebla que ni siquiera notabas — eso es algo verdaderamente hermoso.\nTu mundo espera a que tu verdadero brillo lo atraviese.\nAsí que mantente en pie. Siempre te estamos animando.',
    'En este ciclo, suelta una sola capa de niebla.\nCuanto más sueltes, más se dejará ver tu luz.\nVelamos por ti, siempre.',
    'Stella vela por ti.',
  ];
  static const fullMoonES = [
    'La luna está llena.\nEsto no significa que algo se haya "completado".\nSignifica que la luz del sol ilumina cada rincón de la luna.\nYa no queda dónde esconderse.',
    'Aquello que decidiste soltar —\n«{chosen}»',
    '¿Cómo está esa niebla ahora?\nLa luna llena no sabe mentir.\nSi se ha aclarado o aún permanece —\nde cualquier modo, ya estás en tu plenitud.',
    'Con solo mirar, ya hay luz.',
  ];
  static List<String> catasterismES(int totalDays) => [
    'Durante $totalDays días, cada día creaste una estrella.\nEsos granos de luz se han reunido alrededor de Stella.',
    'Los antiguos miraban el cielo y trazaban líneas entre las estrellas dispersas, hallando historias en ellas.\nUna constelación no es un "hallazgo", sino un "significado".\nLas estrellas siempre estuvieron ahí; fueron las personas quienes les dieron una historia.',
    'Tus días son igual. ¿Qué historia harás de ellos? ¿En qué constelación se convertirán? Eso es solo tuyo, para decidirlo.\nEl poder de dar forma a tu historia vive dentro de ti.\nLlénala de amor y de asombro.\nEste es un mundo donde el amor y la ilusión pueden encontrarse.\nY nosotros te guiaremos hacia ellos.',
    'Cada estrella que creaste es una pequeña luz.\nPero al mirar atrás, aparece una forma: la forma del camino que recorriste.',
    'Aquello que decidiste soltar en este ciclo lunar —\n«{chosen}»',
    '¿Pudiste soltarlo?\nCualquiera de las dos respuestas es la correcta.\nSi lo soltaste, tu constelación graba la forma de esa liberación.\nSi aún estás en camino, tu constelación graba la forma de ese viaje.',
    'Ambas son prueba de que viviste.\nLas constelaciones no se desvanecen jamás. Aunque ahora duela, aunque la historia de tu constelación pese mucho, tu yo del futuro podrá transformar esa historia dolorosa que hoy se graba. Tu yo del futuro vive con fuerza, rodeado de amor. Seguro que todo estará bien.\nTu ser ya es completo. Honramos y acompañamos cada elección y cada decisión que tomaste, día tras día.',
    'Y ahora, recibes una luna nueva.\nPor estar con vida,\nfelicidades.',
  ];

  // ── Português (pt) ──
  static const newMoonPT = [
    'O sol e a lua se encontram.\nNeste instante em que toda a luz se torna uma só,\na tua estrela regressa ao seu brilho original.',
    'O que cobre o teu ser inteiro não veio de fora.\nÉ como uma névoa que, sem dares conta, foste envolvendo à tua volta com o tempo.\nE isso não é culpa tua.\nAs expectativas sociais, os laços de família, as relações de trabalho, o amor… há tanta coisa que pode velar a tua luz.\nMas, por favor, não vejas nisso nada de mau. Amamos-te tal como és, e velaremos por ti para sempre. E vemos-te sempre na tua plenitude.',
    'Ousar dissipar a névoa que nem sequer notavas — isso é algo verdadeiramente belo.\nO teu mundo espera que o teu verdadeiro brilho o atravesse.\nPor isso, mantém-te de pé. Estamos sempre a torcer por ti.',
    'Neste ciclo, solta uma única camada de névoa.\nQuanto mais soltares, mais a tua luz se deixa ver.\nVelamos por ti, sempre.',
    'A Stella vela por ti.',
  ];
  static const fullMoonPT = [
    'A lua está cheia.\nIsto não quer dizer que algo se tenha "completado".\nQuer dizer que a luz do sol ilumina cada recanto da lua.\nJá não há onde se esconder.',
    'Aquilo que decidiste soltar —\n«{chosen}»',
    'Como está essa névoa agora?\nA lua cheia não sabe mentir.\nQuer se tenha dissipado, quer ainda permaneça —\nde qualquer forma, já estás na tua plenitude.',
    'Só de olhar, já há luz.',
  ];
  static List<String> catasterismPT(int totalDays) => [
    'Durante $totalDays dias, criaste uma estrela a cada dia.\nEsses grãos de luz reuniram-se à volta da Stella.',
    'Os antigos olhavam para o céu e traçavam linhas entre as estrelas dispersas, encontrando histórias nelas.\nUma constelação não é uma "descoberta", mas um "sentido".\nAs estrelas sempre estiveram ali; foram as pessoas que lhes deram uma história.',
    'Os teus dias são iguais. Que história farás deles? Em que constelação se tornarão? Isso é só teu, para decidires.\nO poder de dar forma à tua história vive dentro de ti.\nEnche-a de amor e de encanto.\nEste é um mundo onde o amor e a alegria podem ser encontrados.\nE nós guiar-te-emos até eles.',
    'Cada estrela que criaste é uma pequena luz.\nMas, ao olhar para trás, surge uma forma: a forma do caminho que percorreste.',
    'Aquilo que decidiste soltar neste ciclo lunar —\n«{chosen}»',
    'Conseguiste soltá-lo?\nQualquer das duas respostas é a certa.\nSe o soltaste, a tua constelação grava a forma dessa libertação.\nSe ainda estás a caminho, a tua constelação grava a forma dessa viagem.',
    'Ambas são prova de que viveste.\nAs constelações nunca se apagam. Mesmo que agora doa, mesmo que a história da tua constelação pese muito, o teu eu do futuro poderá transformar essa história dolorosa que hoje se grava. O teu eu do futuro vive com força, rodeado de amor. De certeza que vai ficar tudo bem.\nO teu ser já é completo. Honramos e acompanhamos cada escolha e cada decisão que tomaste, dia após dia.',
    'E agora, recebes uma lua nova.\nPor estares com vida,\nparabéns.',
  ];

  // ── Français (fr) ──
  static const newMoonFR = [
    'Le soleil et la lune se rejoignent.\nEn cet instant où toute la lumière ne fait plus qu\'une,\nton étoile retrouve son éclat originel.',
    'Ce qui recouvre ton être tout entier n\'est pas venu du dehors.\nC\'est comme une brume que, sans t\'en apercevoir, tu as enroulée autour de toi au fil du temps.\nEt ce n\'est pas ta faute.\nLes attentes sociales, les liens familiaux, les relations de travail, l\'amour… tant de choses peuvent voiler ta lumière.\nMais, je t\'en prie, n\'y vois rien de mauvais. Nous t\'aimons comme tu es, et nous veillerons sur toi pour toujours. Et nous te voyons toujours dans ta plénitude.',
    'Oser dissiper la brume que tu ne remarquais même pas — c\'est une chose vraiment belle.\nTon monde attend que ton véritable éclat le traverse.\nAlors, tiens-toi debout. Nous t\'encourageons, toujours.',
    'Dans ce cycle, laisse aller une seule couche de brume.\nPlus tu en laisses aller, plus ta lumière se laisse voir.\nNous veillons sur toi, toujours.',
    'Stella veille sur toi.',
  ];
  static const fullMoonFR = [
    'La lune est pleine.\nCela ne veut pas dire que quelque chose est "achevé".\nCela veut dire que la lumière du soleil éclaire chaque recoin de la lune.\nIl n\'y a plus où se cacher.',
    'Ce que tu as choisi de laisser aller —\n«{chosen}»',
    'Où en est cette brume, à présent?\nLa pleine lune ne sait pas mentir.\nQu\'elle se soit dissipée ou qu\'elle demeure encore —\nde toute façon, tu es déjà dans ta plénitude.',
    'Rien qu\'en regardant, il y a déjà de la lumière.',
  ];
  static List<String> catasterismFR(int totalDays) => [
    'Pendant $totalDays jours, tu as créé une étoile chaque jour.\nCes grains de lumière se sont rassemblés autour de Stella.',
    'Les anciens levaient les yeux vers le ciel et traçaient des lignes entre les étoiles éparses, y trouvant des histoires.\nUne constellation n\'est pas une "découverte", mais un "sens".\nLes étoiles ont toujours été là; ce sont les hommes qui leur ont donné une histoire.',
    'Tes jours sont pareils. Quelle histoire en feras-tu? En quelle constellation deviendront-ils? Cela n\'appartient qu\'à toi.\nLe pouvoir de donner forme à ton histoire vit en toi.\nEmplis-la d\'amour et d\'émerveillement.\nC\'est un monde où l\'amour et la joie peuvent se trouver.\nEt nous te guiderons vers eux.',
    'Chaque étoile que tu as créée est une petite lumière.\nMais, en regardant en arrière, une forme apparaît : la forme du chemin que tu as parcouru.',
    'Ce que tu as choisi de laisser aller en ce cycle lunaire —\n«{chosen}»',
    'As-tu pu le laisser aller?\nL\'une et l\'autre réponse sont justes.\nSi tu l\'as laissé aller, ta constellation grave la forme de cette libération.\nSi tu es encore en chemin, ta constellation grave la forme de ce voyage.',
    'Toutes deux sont la preuve que tu as vécu.\nLes constellations ne s\'effacent jamais. Même si tout fait mal en ce moment, même si l\'histoire de ta constellation pèse lourd, ton toi futur pourra transformer cette histoire douloureuse qui se grave aujourd\'hui. Ton toi futur vit avec force, entouré d\'amour. Tout ira bien, c\'est certain.\nTon être est déjà entier. Nous honorons et accompagnons chaque choix et chaque décision que tu as pris, jour après jour.',
    'Et maintenant, tu accueilles une nouvelle lune.\nPour être en vie,\nfélicitations.',
  ];

  // ── Deutsch (de) ──
  static const newMoonDE = [
    'Sonne und Mond begegnen sich.\nIn diesem Augenblick, in dem alles Licht zu einem wird,\nkehrt dein Stern zu seinem ursprünglichen Leuchten zurück.',
    'Was dein ganzes Wesen verhüllt, kam nicht von außen.\nEs ist wie ein Nebel, den du im Lauf der Zeit unbemerkt um dich gelegt hast.\nUnd das ist nicht deine Schuld.\nGesellschaftliche Erwartungen, familiäre Bande, berufliche Beziehungen, die Liebe … so vieles kann dein Licht verschleiern.\nAber bitte sieh darin nichts Schlechtes. Wir haben dich lieb, so wie du bist, und wir werden immer über dich wachen. Und wir sehen dich stets in deiner Ganzheit.',
    'Den Mut zu fassen, den Nebel zu lichten, den du nicht einmal bemerkt hast — das ist etwas wahrhaft Schönes.\nDeine Welt wartet darauf, dass dein wahres Leuchten sie durchdringt.\nAlso steh aufrecht. Wir feuern dich an, immer.',
    'Lass in diesem Zyklus eine einzige Schicht Nebel los.\nJe mehr du loslässt, desto mehr zeigt sich dein Licht.\nWir wachen über dich, immer.',
    'Stella wacht über dich.',
  ];
  static const fullMoonDE = [
    'Der Mond ist voll.\nDas heißt nicht, dass etwas "vollendet" ist.\nEs heißt, dass das Sonnenlicht jede Fläche des Mondes erhellt.\nEs gibt keinen Ort mehr, sich zu verbergen.',
    'Das, was du loslassen wolltest —\n„{chosen}"',
    'Wie steht es nun um diesen Nebel?\nDer Vollmond kann nicht lügen.\nOb er sich gelichtet hat oder noch verweilt —\nso oder so bist du bereits ganz.',
    'Schon das bloße Hinschauen ist selbst ein Licht.',
  ];
  static List<String> catasterismDE(int totalDays) => [
    'An $totalDays Tagen hast du jeden Tag einen Stern erschaffen.\nDiese Lichtkörner haben sich um Stella versammelt.',
    'Die Alten blickten zum Himmel und zogen Linien zwischen den verstreuten Sternen, und fanden Geschichten in ihnen.\nEin Sternbild ist keine "Entdeckung", sondern eine "Bedeutung".\nDie Sterne waren immer da; es waren die Menschen, die ihnen eine Geschichte gaben.',
    'Mit deinen Tagen ist es ebenso. Welche Geschichte machst du aus ihnen? Zu welchem Sternbild werden sie? Das zu entscheiden, liegt ganz bei dir.\nDie Kraft, deiner Geschichte Gestalt zu geben, wohnt in dir.\nFülle sie mit Liebe und mit Staunen.\nDies ist eine Welt, in der Liebe und Freude zu finden sind.\nUnd wir geleiten dich zu ihnen.',
    'Jeder Stern, den du erschaffen hast, ist ein kleines Licht.\nDoch wenn du zurückblickst, zeigt sich eine Gestalt: die Gestalt des Weges, den du gegangen bist.',
    'Das, was du in diesem Mondzyklus loslassen wolltest —\n„{chosen}"',
    'Konntest du es loslassen?\nBeide Antworten sind richtig.\nHast du es losgelassen, so prägt dein Sternbild die Gestalt dieser Befreiung.\nBist du noch unterwegs, so prägt dein Sternbild die Gestalt dieser Reise.',
    'Beides ist ein Beweis dafür, dass du gelebt hast.\nSternbilder verblassen niemals. Auch wenn es jetzt schmerzt, auch wenn die Geschichte deines Sternbilds schwer wiegt — dein künftiges Ich wird diese schmerzvolle Geschichte, die sich heute einprägt, verwandeln können. Dein künftiges Ich lebt mit Kraft, umgeben von Liebe. Es wird ganz gewiss gut.\nDein Wesen ist bereits vollkommen. Wir achten und begleiten jede Wahl und jede Entscheidung, die du Tag für Tag getroffen hast.',
    'Und nun empfängst du einen neuen Neumond.\nDafür, dass du am Leben bist,\nherzlichen Glückwunsch.',
  ];

  // ── 한국어 (ko) ──  ※문법적 성별 없음, 따뜻한 해요체
  static const newMoonKO = [
    '해와 달이 겹쳐요.\n모든 빛이 하나가 되는 이 순간,\n당신의 별도 처음의 빛으로 돌아가요.',
    '온전한 당신을 가리고 있는 것.\n그것은 밖에서 온 것이 아니라,\n어느새 스스로 두르게 된 안개 같은 거예요.\n그렇게 둘러버린 건 당신의 잘못이 아니에요.\n사회적인 기대, 가족 관계, 일에서의 관계, 사랑… 당신을 가리는 일은 참 많아요.\n하지만, 그것을 나쁜 일이라고 여기지 말아요. 우리는 그런 당신마저 사랑스럽게 느끼며, 언제까지나 지켜보고 있어요. 그리고 우리는 언제나, 온전한 당신을 보고 있어요.',
    '자신도 모르게 둘러버린 안개를 걷어내려 하는 것.\n그건 정말로 아름다운 일이에요.\n당신이 만드는 세계는, 당신의 진짜 빛이 풀려나기를 바라고 있어요.\n그러니 당당히 서요. 우리는 늘 당신을 응원하고 있어요.',
    '이번 주기에는, 안개 한 겹을 내려놓아요.\n내려놓을수록, 당신의 빛이 더 잘 보이게 돼요.\n우리는 언제나 당신을 지켜보고 있어요.',
    'Stella가 당신을 지켜보고 있어요.',
  ];
  static const fullMoonKO = [
    '달이 가득 찼어요.\n이건 무언가가 "완성된" 것이 아니에요.\n태양의 빛이 달의 온 표면을 비추고 있다는 것.\n숨을 곳이 없어졌다는 뜻이에요.',
    '당신이 내려놓으려 한 것 —\n「{chosen}」',
    '지금, 그 안개는 어떤가요?\n보름달의 빛은 거짓말을 못 해요.\n옅어졌든, 아직 그대로든 —\n어느 쪽이든, 당신은 이미 온전해요.',
    '그저 바라보는 것만으로도 빛이 돼요.',
  ];
  static List<String> catasterismKO(int totalDays) => [
    '$totalDays일 동안, 당신은 매일 하나의 별을 만들어 왔어요.\n그 빛의 알갱이들이 Stella의 곁에 모였어요.',
    '옛사람들은 하늘을 올려다보며,\n흩어진 별을 선으로 잇고, 그 안에서 이야기를 찾아냈어요.\n별자리란 "발견"이 아니라 "의미 짓기"예요.\n별은 늘 그 자리에 있었고, 사람들이 거기에 이야기를 주었어요.',
    '당신의 나날도 그래요. 당신의 나날을 어떤 이야기로, 어떤 별자리로 만들까요? 그건 당신이 자유롭게 정할 수 있어요.\n당신의 삶에 이야기를 주는 힘은, 당신 안에 있어요.\n사랑과 설렘이 가득한 의미를 붙여보지 않을래요?\n사랑과 설렘을 찾을 수 있는 이 세계.\n우리는 당신을 사랑과 설렘으로 이끌어요.',
    '매일 만든 하나하나의 별은 작은 빛.\n하지만 돌아보면, 거기에 형태가 떠올라요. 당신이 걸어온 형태가 있어요.',
    '이번 달의 주기에서 당신이 내려놓으려 한 것 —\n「{chosen}」',
    '내려놓을 수 있었나요?\n어느 쪽 대답이든 옳아요.\n내려놓았다면, 당신의 별자리는 그 해방의 형태를 새겨요.\n아직 가는 중이라면, 당신의 별자리는 그 여정의 형태를 새겨요.',
    '둘 다, 당신이 살아온 증거예요.\n별자리는 영원히 사라지지 않아요. 지금이 너무 힘들고 괴로워서, 별자리의 이야기가 아주 무거운 것이라 해도, 미래의 당신은 지금 새겨진 이 괴로운 이야기를 다시 써낼 수 있어요. 미래의 당신은 아주 강하고, 사랑이 가득한 가운데 살아가고 있어요. 분명, 괜찮을 거예요.\n당신은 이미 온전한 존재예요. 당신이 날마다 내린 모든 선택과 결정을, 우리는 존중하고 응원해요.',
    '그리고 당신은, 다시 새로운 달을 맞이해요.\n당신이 살아 있다는 것에 —\n축하해요.',
  ];

  // ── 言語選択 (languageCode で分岐。未対応は EN) ──
  static String _lang(String locale) {
    final code = locale.toLowerCase();
    if (code.startsWith('ja')) return 'ja';
    if (code.startsWith('es')) return 'es';
    if (code.startsWith('pt')) return 'pt';
    if (code.startsWith('fr')) return 'fr';
    if (code.startsWith('de')) return 'de';
    if (code.startsWith('ko')) return 'ko';
    return 'en';
  }

  static List<String> getNewMoon(String locale) {
    switch (_lang(locale)) {
      case 'ja': return newMoonJP;
      case 'es': return newMoonES;
      case 'pt': return newMoonPT;
      case 'fr': return newMoonFR;
      case 'de': return newMoonDE;
      case 'ko': return newMoonKO;
      default: return newMoonEN;
    }
  }

  static List<String> _fullMoon(String locale) {
    switch (_lang(locale)) {
      case 'ja': return fullMoonJP;
      case 'es': return fullMoonES;
      case 'pt': return fullMoonPT;
      case 'fr': return fullMoonFR;
      case 'de': return fullMoonDE;
      case 'ko': return fullMoonKO;
      default: return fullMoonEN;
    }
  }

  static List<String> getFullMoon(String locale, String chosenText) =>
      _fullMoon(locale).map((t) => t.replaceAll('{chosen}', chosenText)).toList();

  static List<String> _catasterism(String locale, int totalDays) {
    switch (_lang(locale)) {
      case 'ja': return catasterismJP(totalDays);
      case 'es': return catasterismES(totalDays);
      case 'pt': return catasterismPT(totalDays);
      case 'fr': return catasterismFR(totalDays);
      case 'de': return catasterismDE(totalDays);
      case 'ko': return catasterismKO(totalDays);
      default: return catasterismEN(totalDays);
    }
  }

  static List<String> getCatasterism(String locale, int totalDays, String chosenText) =>
      _catasterism(locale, totalDays).map((t) => t.replaceAll('{chosen}', chosenText)).toList();
}
