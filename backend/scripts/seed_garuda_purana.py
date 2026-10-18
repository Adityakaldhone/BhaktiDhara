"""
Garuda Purana Saroddhara (गरुड पुराण सारोद्धार) Database Seeder
Seeds all 16 sacred chapters with Sanskrit Shlokas, English Transliteration,
and Marathi, Hindi, and English translations.
"""

import os
import sys
import sqlite3
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BACKEND_DIR / "data" / "bhaktidhara.db"

GARUDA_CHAPTERS = [
    {
        "chapter_number": 1,
        "name_sanskrit": "मरणोत्तरगतिवर्णनम्",
        "name_mr": "मरणोत्तर गती आणि यममार्ग उपक्रम",
        "name_hi": "मरणोत्तर गति और यममार्ग उपक्रम",
        "name_en": "The Miseries of the Sinful in this World and the Other",
        "summary_mr": "भगवंतांच्या मधुसूदन रूपाचे मंगलाचरण, शौनक ऋषींचा प्रश्न आणि भगवान विष्णू व गरुड यांच्यातील संवाद. पापी जीवांची मरणोत्तर दशा, यमदूतांचे आगमन आणि यमलोकाची वाटचाल.",
        "summary_hi": "भगवान विष्णु और गरुड़ जी के संवाद का प्रारंभ, पापी मनुष्यों की मृत्यु के समय दशा, यमदूतों का आगमन और यममार्ग की भयानकता का वर्णन।",
        "summary_en": "The opening dialogue between Lord Vishnu and Garuda, describing the departure of the sinful soul from the body, arrival of Yama's messengers, and the harsh realities of the afterlife.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "धर्मदृढबद्धमूलो वेदस्कन्धः पुराणशाखाढ्यः ।\nक्रतुकुसुमो मोक्षफलो मधुसूदनपादपो जयति ॥",
                "transliteration": "dharmadṛḍhabaddhamūlo vedaskandhaḥ purāṇaśākhāḍhyaḥ |\nkratukusumo mokṣaphalo madhusūdanapādapo jayati ||",
                "meaning_mr": "धर्म ज्याचे सुदृढ मूळ आहे, वेद ज्याचे खोड आहे, पुराणे ज्याच्या विशाल शाखा आहेत, यज्ञ हे ज्याची फुले आहेत आणि मोक्ष हे ज्याचे अमृतमय फळ आहे, अशा भगवान मधुसूदन रूपी दिव्य कल्पवृक्षाचा विजय असो.",
                "meaning_hi": "धर्म जिसकी सुदृढ़ जड़ है, वेद जिसका तना हैं, पुराण जिसकी शाखाएं हैं, यज्ञ जिसके पुष्प हैं और मोक्ष जिसका दिव्य फल है—ऐसे भगवान मधुसूदन रूपी कल्पवृक्ष की जय हो।",
                "meaning_en": "Victorious is the divine tree Madhusudana, whose firm root is Dharma, whose trunk is the Vedas, whose abundant branches are the Puranas, whose flowers are sacred sacrifices, and whose fruit is ultimate liberation."
            },
            {
                "verse_number": 2,
                "slok": "शौनकाद्या महाभागा नैमिषे सूतमागतम् ।\nपप्रच्छुः करुणाविष्टाः सर्वलोकहितैषिणः ॥",
                "transliteration": "śaunakādyā mahābhāgā naimiṣe sūtamāgatam |\npapracchuḥ karuṇāviṣṭāḥ sarvalokahitaiṣiṇaḥ ||",
                "meaning_mr": "नैमिषारण्यात शौनकादी परम तपस्वी महामुनींनी, सर्व प्राणिमात्रांच्या कल्याणासाठी करुणेने भरून, उपस्थित सूतजींना आदरपूर्वक प्रश्न विचारला.",
                "meaning_hi": "नैमिषारण्य तीर्थ में शौनक आदि परम तपस्वी महर्षियों ने, समस्त लोकों के कल्याण की भावना से भरकर, सूत जी से आदरपूर्वक पूछा।",
                "meaning_en": "In the sacred forest of Naimisha, the great sages led by Shaunaka, filled with deep compassion for all living beings, respectfully inquired of the revered Suta."
            },
            {
                "verse_number": 3,
                "slok": "सुखदः स्वर्गमार्गस्तु कथितो भवता मुने ।\nअधुना श्रोतुमिच्छामो यममार्गं सुदारुणम् ॥",
                "transliteration": "sukhadaḥ svargamārgastu kathito bhavatā mune |\nadhunā śrotumicchāmo yamamārgaṃ sudāruṇam ||",
                "meaning_mr": "ऋषी म्हणाले: हे मुनिवर्य! आपण पुण्यवानांचा सुखकारक स्वर्गमार्ग आम्हाला सांगितला; आता पापात्मे ज्या भयानक यममार्गावरून जातात, त्या यममार्गाचे स्वरूप ऐकण्याची आमची इच्छा आहे.",
                "meaning_hi": "ऋषियों ने कहा: हे मुनिवर! आपने पुण्यवानों का सुखद देवयान मार्ग तो बताया; अब हम पापियों के अत्यंत कष्टप्रद और भयानक यममार्ग के विषय में सुनना चाहते हैं।",
                "meaning_en": "The sages said: You have previously described the auspicious path of the righteous; now we desire to hear about the terrifying path of Yama along which the sinful must travel."
            },
            {
                "verse_number": 4,
                "slok": "सूत उवाच -\nशृणुध्वं मुनयः सर्वे यत्पृष्टं लोकतुष्टये ।\nतत्प्रवक्ष्यामि यत्प्रोक्तं गरुडाय गदाभृता ॥",
                "transliteration": "sūta uvāca -\nśṛṇudhvaṃ munayaḥ sarve yatpṛṣṭaṃ lokatuṣṭaye |\ntatpravakṣyāmi yatproktaṃ garuḍāya gadābhṛtā ||",
                "meaning_mr": "सूतजी म्हणाले: हे महर्षींनो! लोकांच्या उद्धारासाठी आपण जो प्रश्न विचारला आहे, तेच पूर्वी भगवान श्रीहरी विष्णूंनी गरुडाला सांगितले होते; ते मी आपणास सविस्तर सांगतो.",
                "meaning_hi": "सूत जी बोले: हे महर्षियों! लोकों के कल्याण हेतु आपने जो पूछा है, वही रहस्य एक बार भगवान विष्णु ने गरुड़ जी को बताया था; वह मैं आपसे कहता हूँ।",
                "meaning_en": "Suta said: Listen, O sages! What you have inquired for the welfare of humanity is precisely what Lord Vishnu revealed to Garuda; that very sacred knowledge I now declare."
            },
            {
                "verse_number": 5,
                "slok": "एकदा सुखमासीनं वैकुण्ठे मुनिपूजितम् ।\nविनतानन्दनो भक्त्या प्रणम्यैतदपृच्छत ॥",
                "transliteration": "ekadā sukhamāsīnaṃ vaikuṇṭhe munipūjitam |\nvinatānandano bhaktyā praṇamyaitadapṛcchata ||",
                "meaning_mr": "एके दिवशी वैकुंठधामात सुखपूर्वक विराजमान असलेल्या भगवान विष्णूंच्या चरणी नतमस्तक होऊन पक्षीराज गरुडाने भक्तीभावाने विचारले.",
                "meaning_hi": "एक समय वैकुण्ठ में सुखपूर्वक विराजमान भगवान श्रीहरि को विनीत भाव से प्रणाम करके पक्षीराज गरुड़ ने यह प्रश्न पूछा।",
                "meaning_en": "Once, when the Supreme Lord Vishnu was seated peacefully in Vaikuntha, Garuda bowed low with devotion and reverently posed this inquiry."
            },
            {
                "verse_number": 6,
                "slok": "गरुड उवाच -\nभक्तियोगो मया ज्ञातः त्वन्मुखादमृतोपमः ।\nअधुना श्रोतुमिच्छामि यमलोकगतिं प्रभो ॥",
                "transliteration": "garuḍa uvāca -\nbhaktiyogo mayā jñātaḥ tvanmukhādamṛtopamaḥ |\nadhunā śrotumicchāmi yamalokagatiṃ prabho ||",
                "meaning_mr": "गरुड म्हणाले: हे प्रभो! आपल्या मुखातून मी अमृततुल्य भक्तियोग ऐकला; आता जे मनुष्य धर्म आणि भक्तीपासून विन्मुख राहतात, त्यांच्या मरणोत्तर यमलोकाच्या गतीविषयी सांगा.",
                "meaning_hi": "गरुड़ जी बोले: हे प्रभु! आपके श्रीमुख से मैंने अमृत समान भक्तियोग सुना; अब जो मनुष्य धर्म और ईश्वरविमुख रहते हैं, उनके यमलोक गमन का रहस्य मुझे बताइए।",
                "meaning_en": "Garuda said: O Lord! I have heard from Your nectarous lips the glory of devotion; now I wish to understand the journey to Yama's abode taken by souls who turn away from righteousness."
            },
            {
                "verse_number": 7,
                "slok": "श्रीभगवानुवाच -\nशृणु तार्क्ष्य प्रवक्ष्यामि यत्त्वया परिपृच्छितम् ।\nयममार्गस्य वृत्तं च पापिनां दुःखदायकम् ॥",
                "transliteration": "śrībhagavānuvāca -\nśṛṇu tārkṣya pravakṣyāmi yattvayā paripṛcchitam |\nyamamārgasya vṛttaṃ ca pāpināṃ duḥkhadāyakam ||",
                "meaning_mr": "भगवान श्रीकृष्ण म्हणाले: हे गरुडा! तू जे विचारलेस ते मी सांगतो. पापी जिवांना अत्यंत दुःख देणाऱ्या यममार्गाचे भयानक वृत्त नीट ऐक.",
                "meaning_hi": "भगवान श्रीहरि बोले: हे गरुड़! सुनो, तुमने जो पूछा है वह मैं बताता हूँ। पापी मनुष्यों को अत्यंत दारुण दुःख देने वाले यममार्ग का वृत्तांत ध्यानपूर्वक सुनो।",
                "meaning_en": "The Blessed Lord said: Listen, O Garuda! I shall reveal to you that which you have asked: the harrowing journey of the sinful along the painful path of Yama."
            },
            {
                "verse_number": 8,
                "slok": "धर्महीना दुराचाराः परद्रव्यापहारिणः ।\nअधर्मनिरता ये च ते प्रयान्ति यमालयम् ॥",
                "transliteration": "dharmahīnā durācārāḥ paradravyāpahāriṇaḥ |\nadharmaniratā ye ca te prayānti yamālayam ||",
                "meaning_mr": "जे मनुष्य धर्महीन, दुराचारी, दुसऱ्यांचे धन लुटणारे आणि नेहमी अधर्मात मग्न असतात, तेच मरणोत्तर यमलोकात जातात.",
                "meaning_hi": "जो मनुष्य धर्म से हीन, दुराचारी, दूसरों के धन को हड़पने वाले और सदैव पाप में लिप्त रहते हैं, वे ही मृत्यु के बाद यमलोक जाते हैं।",
                "meaning_en": "Those who are devoid of dharma, vicious in conduct, covetous of others' wealth, and persistent in unrighteousness—they inevitably tread the dark way to Yama's abode."
            },
            {
                "verse_number": 9,
                "slok": "प्राणप्रयाणसमये भीतो भवति मानवः ।\nकण्ठरोधो भवेत्तस्य चेष्टते इतस्ततः ॥",
                "transliteration": "prāṇaprayāṇasamaye bhīto bhavati mānavaḥ |\nkaṇṭharodho bhavettasya ceṣṭate itastataḥ ||",
                "meaning_mr": "अंतकाळी प्राणाचा निरोप घेताना असा पापी मनुष्य भयाने व्याकूळ होतो; त्याचा कंठ कफाने दाटून येतो आणि तो जीवाच्या आकांताने तळमळू लागतो.",
                "meaning_hi": "प्राण छूटने के अंतिम समय में मनुष्य अत्यंत भयभीत हो जाता है; उसका गला रुंध जाता है और वह छटपटाने लगता है।",
                "meaning_en": "At the moment of the soul's departure, the sinful person becomes seized with terror; speech fails, the throat chokes, and the body writhes in anguish."
            },
            {
                "verse_number": 10,
                "slok": "ततः सम्प्राप्यते क्रूरैः दूतैर्वै यमकिङ्करैः ।\nपाशैर्बद्ध्वा नयन्त्याशु यमलोकं सुदारुणम् ॥",
                "transliteration": "tataḥ samprāpyate krūraiḥ dūtairvai yamakiṅkaraiḥ |\npāśairbaddhvā nayantyāśu yamalokaṃ sudāruṇam ||",
                "meaning_mr": "त्यानंतर भयंकर आणि क्रूर यमदूत तिथे येतात, आणि जीवाच्या सूक्ष्म देहाला पाशांनी बांधून अतिशय दुर्गम यममार्गावरून ओढत नेतात.",
                "meaning_hi": "तब अत्यंत विकराल और क्रूर यमदूत आकर जीवात्मा को पाशों में बांध लेते हैं और उसे घसीटते हुए भयानक यममार्ग पर ले चलते हैं।",
                "meaning_en": "Then arrive the fierce and unrelenting emissaries of Yama; binding the subtle form with nooses, they drag the helpless soul along the dreadful highway."
            },
            {
                "verse_number": 11,
                "slok": "न बान्धवो न भार्या च न पुत्रास्तत्र तारकाः ।\nकेवलं धर्ममेवैको सहायो भवति प्रभो ॥",
                "transliteration": "na bāndhavo na bhāryā ca na putrāstatra tārakāḥ |\nkevalaṃ dharmamevaiko sahāyo bhavati prabho ||",
                "meaning_mr": "त्या मार्गावर ना नातेवाईक, ना पत्नी, ना मुले मदतीला धावून येतात; केवळ मनुष्याने आयुष्यभरात कमावलेला 'धर्म' हाच त्याचा एकमेव खरा सखा आणि तारणहार ठरतो.",
                "meaning_hi": "उस परलोक मार्ग में न बंधु, न पत्नी और न पुत्र साथ देते हैं; केवल मनुष्य द्वारा किया गया शुद्ध 'धर्म' ही उसका एकमात्र सच्चा सहायक होता है।",
                "meaning_en": "Neither kinsmen, nor spouse, nor offspring can aid the traveler on that road; Dharma alone, accumulated through righteous living, remains the sole companion and savior."
            }
        ]
    },
    {
        "chapter_number": 2,
        "name_sanskrit": "यममार्गवर्णनम्",
        "name_mr": "यममार्गाचे भयानक स्वरूप व वैतरणी नदी",
        "name_hi": "यममार्ग का भयानक स्वरूप और वैतरणी नदी",
        "name_en": "The Way of Yama and the River Vaitarani",
        "summary_mr": "यमलोकाकडे जाणाऱ्या ८६ हजार योजनांच्या अतिशय दुर्गम मार्गाचे वर्णन. अन्न, जल आणि सावली नसलेला मार्ग आणि रक्त-पूयाने भरलेली भयंकर वैतरणी नदी.",
        "summary_hi": "यमलोक के दुर्गम मार्ग का विस्तार से विवरण, प्यास, भूख और प्रचंड धूप से पीड़ित जीवात्मा की व्यथा तथा भयानक वैतरणी नदी का स्वरूप।",
        "summary_en": "A vivid account of the harrowing path to the realm of Yama spanning thousands of leagues without water or shade, and the dreadful crossing of the River Vaitarani.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "षडशीतिसहस्राणि योजनानां प्रमाणतः ।\nयममार्गो महाघोरः पापिनां परिकीर्तितः ॥",
                "transliteration": "ṣaḍaśītisahasrāṇi yojanānāṃ pramāṇataḥ |\nyamamārgo mahāghoraḥ pāpināṃ parikīrtitaḥ ||",
                "meaning_mr": "यमलोकाचा मार्ग हा चौऱ्यांशी ते शहाऐंशी हजार योजनांचा अतिशय प्रदीर्घ आणि पापी लोकांसाठी अत्यंत घोर व भयानक सांगितला आहे.",
                "meaning_hi": "यमलोक का मार्ग छियासी हजार योजन लंबा है; यह मार्ग पापियों के लिए अत्यंत भीषण, कंटकाकीर्ण और भयंकर बताया गया है।",
                "meaning_en": "The terrifying highway to Yama's city extends for eighty-six thousand leagues, a path filled with utter dread for unrepentant souls."
            },
            {
                "verse_number": 2,
                "slok": "न तत्र छाया वृक्षाणां न तोयं यत्र लभ्यते ।\nतपन्ति द्वादशादित्या युगान्त इव पावकः ॥",
                "transliteration": "na tatra chāyā vṛkṣāṇāṃ na toyaṃ yatra labhyate |\ntapanti dvādaśādityā yugānta iva pāvakaḥ ||",
                "meaning_mr": "त्या मार्गावर विश्रांतीसाठी एकाही वृक्षाची सावली नाही आणि पिण्यासाठी पाण्याचा एक थेंबही मिळत नाही; जणू प्रलयकाळात बारा सूर्य एकदम तळपतात तसा प्रचंड दाह तिथे होतो.",
                "meaning_hi": "उस मार्ग में न तो वृक्षों की छाया है और न कहीं जल मिलता है; प्रलयकाल के समान बारह सूर्य वहाँ निरंतर प्रचंड ताप बरसाते हैं।",
                "meaning_en": "There is neither the cooling shade of trees nor a drop of water along that road; twelve blazing suns beat down as though the dissolution of the universe had arrived."
            },
            {
                "verse_number": 3,
                "slok": "क्वचिच्छीतं महद्घोरं क्वचित्कण्टकसङ्कुलम् ।\nक्वचिद्व्यालकुलाकीर्णं क्वचित्पाषाणदारुणम् ॥",
                "transliteration": "kvacicchītaṃ mahadghoraṃ kvacitkaṇṭakasaṅkulam |\nkvacidvyālakulākīrṇaṃ kvacitpāṣāṇadāruṇam ||",
                "meaning_mr": "कुठे हाडे गोठवणारी भयानक थंडी, कुठे तीक्ष्ण काट्यांची राने, कुठे विषारी सर्पांचे समुदाय, तर कुठे तीक्ष्ण दगडांची वाट जीवाने पार करावी लागते.",
                "meaning_hi": "कहीं असह्य हाड़ कंपाने वाली ठंड है, कहीं नुकीले काँटों का वन है, कहीं भयानक विषैले सर्प हैं, और कहीं धारदार तीखे पत्थरों का दुर्गम पथ है।",
                "meaning_en": "In some tracts reigns bone-chilling frost, in others thickets of sharp thorns; here crawl venomous serpents, and there lie razored stones that shred the traveler's feet."
            },
            {
                "verse_number": 4,
                "slok": "वैतरणी नाम नदी तन्मध्ये समवस्थिता ।\nरक्तपूयवहा घोरा मांसशोणितकर्दमा ॥",
                "transliteration": "vaitaraṇī nāma nadī tanmadhye samavasthitā |\nraktapūyavahā ghorā māṃsaśoṇitakardamā ||",
                "meaning_mr": "त्या मार्गाच्या मध्यभागी 'वैतरणी' नावाची भयंकर नदी वाहते; त्या नदीत पाण्याचा थेंब नसून केवळ रक्त, पू आणि मांसाचा चिखल खदखदत असतो.",
                "meaning_hi": "उस मार्ग के बीच में 'वैतरणी' नामक अत्यंत डरावनी नदी बहती है, जिसमें जल के स्थान पर केवल रक्त, पीब और मांस का खौलता हुआ कीचड़ बहता है।",
                "meaning_en": "In the midst of that journey lies the dreadful River Vaitarani, surging not with cool water, but with torrents of blood, pus, and boiling marrow."
            },
            {
                "verse_number": 5,
                "slok": "गोधर्मदानरहिताः पाशबद्धा ह्यनाथवत् ।\nतस्यां मज्जन्ति पापिष्ठाः क्रन्दमाना मुहुर्मुहुः ॥",
                "transliteration": "godharmadānarahitāḥ pāśabaddhā hyanāthavat |\ntasyāṃ majjanti pāpiṣṭhāḥ krandamānā muhurmuhuḥ ||",
                "meaning_mr": "ज्यांनी आयुष्यात गोदान किंवा धर्मकार्य केले नाही, ते पापी जीवात्मे पाशाने बांधून अनाथ प्राण्यासारखे त्या वैतरणीत बुडवले जातात आणि आक्रोश करू लागतात.",
                "meaning_hi": "जिन्होंने जीवन में गोदान या सत्कर्म नहीं किए, वे पापी जीव यमपाश में बंधकर अनाथों की तरह उस वैतरणी में डूबते हैं और करुण क्रंदन करते हैं।",
                "meaning_en": "Those who performed neither charity nor the sacred gift of a cow are bound fast by Yama's cords and plunged like orphans into Vaitarani, weeping bitterly."
            },
            {
                "verse_number": 6,
                "slok": "दानशीला महात्मानः सत्यव्रतपरायणाः ।\nसुखेन तरणं यान्ति नावमारुह्य वैष्णवीम् ॥",
                "transliteration": "dānaśīlā mahātmānaḥ satyavrataparāyaṇāḥ |\nsukhena taraṇaṃ yānti nāvamāruhya vaiṣṇavīm ||",
                "meaning_mr": "परंतु जे दानशूर, महात्मा आणि सत्यनिष्ठ असतात, ते भगवान विष्णूंच्या कृपेने मिळालेल्या दिव्य नौकेत बसून ती नदी अतिशय सुखाने पार करतात.",
                "meaning_hi": "किन्तु जो दानशील, सत्यवादी और सदाचारी पुण्यात्मा होते हैं, वे भगवान की कृपा से प्राप्त दिव्य नौका पर बैठकर उस नदी को सुखपूर्वक पार कर लेते हैं।",
                "meaning_en": "Yet the noble, the truthful, and the charitable ascend a divine celestial vessel by Vishnu's grace and effortlessly cross over the perilous river."
            }
        ]
    },
    {
        "chapter_number": 3,
        "name_sanskrit": "यमयातनावर्णनम्",
        "name_mr": "यमपुरी, चित्रगुप्त सभा आणि यमयातना",
        "name_hi": "यमपुरी, चित्रगुप्त की सभा और यमयातना",
        "name_en": "The Torments of Yama and the Assembly of Chitragupta",
        "summary_mr": "यमराजांची विशाल न्यायसभा, चित्रगुप्त आणि श्रवण नावाच्या गुप्त दूतांचे हिशेब. जीवाच्या पाप-पुण्याचा निवाडा आणि विविध प्रकारच्या तीव्र यमयातना.",
        "summary_hi": "धर्मराज यम की सभा, चित्रगुप्त द्वारा कर्मों का लेखा-जोखा और पापकर्मियों को दी जाने वाली कठोर यातनाओं का प्रामाणिक निरूपण।",
        "summary_en": "The grand judgment hall of King Yama, Chitragupta's impartial audit of worldly deeds, and the retribution administered to unrighteous souls.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "ततः पश्यन्ति ते सर्वे धर्मराजं महाबलम् ।\nदण्डहस्तं महाकायं महिषस्थं भयावहम् ॥",
                "transliteration": "tataḥ paśyanti te sarve dharmarājaṃ mahābalam |\ndaṇḍahastaṃ mahākāyaṃ mahiṣasthaṃ bhayāvaham ||",
                "meaning_mr": "त्यानंतर ते पापी जीव अत्यंत शक्तिमान, हाती काळदण्ड धारण केलेल्या, रेड्यावर स्वार झालेल्या आणि विशाल रूप धारण केलेल्या धर्मराज यमदेवांना पाहतात.",
                "meaning_hi": "तदुपरांत वे पापी जीव हाथ में कालदंड लिए, विशालकाय भैंसे पर आरूढ़ और प्रलयकारी स्वरूप वाले धर्मराज यम का दर्शन करते हैं।",
                "meaning_en": "There the souls behold the formidable King of Justice, colossal in form, holding the rod of cosmic law, mounted upon a ferocious black buffalo."
            },
            {
                "verse_number": 2,
                "slok": "चित्रगुप्तश्च तत्रास्ते सर्वकर्मप्रदर्शकः ।\nयथाकृतं कृतं कर्म लिख्यते यस्य पुस्तके ॥",
                "transliteration": "citraguptaśca tatrāste sarvakarmapradarśakaḥ |\nyathākṛtaṃ kṛtaṃ karma likhyate yasya pustake ||",
                "meaning_mr": "तिथे चित्रगुप्त बसलेले असतात, ज्यांच्या ग्रंथात मानवाने गुप्त किंवा उघडपणे केलेल्या प्रत्येक चांगल्या-वाईट कर्माची नोंद तंतोतंत लिहिलेली असते.",
                "meaning_hi": "वहीं चित्रगुप्त विराजमान रहते हैं, जिनकी पुस्तक में मनुष्य द्वारा गुप्त या प्रत्यक्ष रूप से किए गए प्रत्येक कर्म का यथार्थ लेखा-जोखा दर्ज होता है।",
                "meaning_en": "Beside him sits Chitragupta, the recorder of destiny, who maintains in his imperishable register an accurate chronicle of every human thought and deed."
            },
            {
                "verse_number": 3,
                "slok": "श्रवणा नाम तद्दूताः सूर्यचन्द्राग्निसन्निभाः ।\nपश्यन्ति प्राणिनां वृत्तं गुप्तं वा यदि वा रहः ॥",
                "transliteration": "śravaṇā nāma taddūtāḥ sūryacandrāgnisannibhāḥ |\npaśyanti prāṇināṃ vṛttaṃ guptaṃ vā yadi vā rahaḥ ||",
                "meaning_mr": "सूर्य, चंद्र आणि अग्नीप्रमाणे सर्वत्र उपस्थित राहणारे 'श्रवण' नावाचे देवदूत मनुष्याचे एकांतात केलेले गुप्त कर्मही पाहतात आणि यमदरबारी साक्ष देतात.",
                "meaning_hi": "सूर्य, चंद्रमा और अग्नि के समान सर्वव्यापी 'श्रवण' नामक दूत प्राणियों के एकांत में किए गए गुप्त कर्मों को भी साक्षी रूप में देखते हैं।",
                "meaning_en": "The omniscient emissaries known as the Shravanas, luminous like the sun and moon, witness every deed performed in secret and testify with absolute truth."
            },
            {
                "verse_number": 4,
                "slok": "कुम्भीपाकेषु पच्यन्ते रौरवे तामिस्रे तथा ।\nअसिपत्रवने तीक्ष्णे छिद्यन्ते पापकर्मिणः ॥",
                "transliteration": "kumbhīpākeṣu pacyante raurave tāmisre tathā |\nasipatravane tīkṣṇe chidyante pāpakarmiṇaḥ ||",
                "meaning_mr": "पापी जीवांना कुंभीपाक, रौरव आणि अंधतामिस्र नरकात खदखदत्या तेलात उकळले जाते आणि तलवारीसारखी तीक्ष्ण पाने असलेल्या असिपत्रवनात कापले जाते.",
                "meaning_hi": "पापियों को कुम्भीपाक, रौरव और महातामिस्र जैसे नरकों में खौलते तेल में पकाया जाता है तथा असिपत्रवन में तलवार जैसे पत्तों से काटा जाता है।",
                "meaning_en": "The sinful are boiled in the cauldron of Kumbhipaka, cast into Raurava and Tamisra, and sliced by the razor-edged foliage of Asipatravana."
            },
            {
                "verse_number": 5,
                "slok": "कर्मणा प्राप्यते सर्वं सुखं दुःखं च देहिभिः ।\nनादत्तं लभते कश्चित् कृत्वा कर्म शुभाशुभम् ॥",
                "transliteration": "karmaṇā prāpyate sarvaṃ sukhaṃ duḥkhaṃ ca dehibhiḥ |\nnādattaṃ labhate kaścit kṛtvā karma śubhāśubham ||",
                "meaning_mr": "सर्व जीवांना त्यांच्या कर्मानेच सुख अथवा दुःख मिळते; पेरल्याशिवाय काही उगवत नाही, म्हणून मनुष्य आपल्याच बऱ्या-वाईट कर्मांचे फळ भोगतो.",
                "meaning_hi": "सभी प्राणियों को अपने ही कर्मों के अनुसार सुख और दुःख प्राप्त होता है; बिना बोए कुछ नहीं मिलता, मनुष्य अपने ही भले-बुरे कर्मों का फल पाता है।",
                "meaning_en": "By one's own actions alone does an embodied being inherit joy or misery; none reaps what has not been sown through actions auspicious or corrupt."
            }
        ]
    },
    {
        "chapter_number": 4,
        "name_sanskrit": "नरककर्मविपाकः",
        "name_mr": "विविध पापकर्मांचे फळ आणि नरकवर्णन",
        "name_hi": "पाप कर्मों का फल और नरक वर्णन",
        "name_en": "The Sins which Lead to the Hells",
        "summary_mr": "कोणत्या दुष्कृत्यांमुळे, फसवणुकीमुळे, गुरुद्रोहामुळे आणि जीवहत्त्येमुळे रौरव, कुंभीपाक इत्यादी भयंकर नरकांची प्राप्ती होते याचे सविस्तर वर्णन.",
        "summary_hi": "गुरुद्रोह, विश्वासघात, परस्त्रीगमन और निर्दोष जीवों की हिंसा जैसे घोर पापों के फलस्वरूप मिलने वाले रौरव, तामिस्र और कुंभीपाक नरकों का वर्णन।",
        "summary_en": "An enumeration of specific unrighteous actions such as betrayal, cruelty, greed, and arrogance, and the precise infernal realms they incur.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "मातृहा पितृहा चैव गुरुद्रोही च मानवः ।\nब्रह्महा मित्रघाती च पच्यन्ते रौरवे चिरम् ॥",
                "transliteration": "mātṛhā pitṛhā caiva gurudrohī ca mānavaḥ |\nbrahmahā mitraghātī ca pacyante raurave ciram ||",
                "meaning_mr": "आई, वडील, गुरु यांच्याशी द्रोह करणारा, निरपराध्यांची हत्या करणारा आणि मित्राचा विश्वासघात करणारा मनुष्य दीर्घकाळ रौरव नरकात यातना भोगतो.",
                "meaning_hi": "माता-पिता और गुरु से द्रोह करने वाला, ज्ञानी पुरुषों की हत्या करने वाला और मित्र से विश्वासघात करने वाला मनुष्य दीर्घकाल तक रौरव नरक में पड़ता है।",
                "meaning_en": "He who injures his mother, father, or preceptor, slays the innocent, or betrays a trusting friend, languishes for ages in the fires of Raurava."
            },
            {
                "verse_number": 2,
                "slok": "देवद्रव्यापहर्ता च परदाररतः सदा ।\nविश्वासघाती कृपणो वसते कालसूत्रके ॥",
                "transliteration": "devadravyāpahartā ca paradārarataḥ sadā |\nviśvāsaghātī kṛpaṇo vasate kālasūtrake ||",
                "meaning_mr": "मंदिराचे किंवा देवधर्माचे धन हडपणारा, परस्त्रीचा अभिलाष धरणारा, विश्वासघातकी आणि लोभी मनुष्य कालसूत्र नावाच्या भयानक नरकात पडतो.",
                "meaning_hi": "मंदिरों और धर्म के धन का हरण करने वाला, परस्त्रीगामी, विश्वासघाती और कंजूस मनुष्य कालसूत्र नामक भयंकर नरक में निवास करता है।",
                "meaning_en": "He who plunders temple wealth, lusts after the wives of others, breaks sworn trusts, or hoards maliciously, enters the burning snare of Kalasutra."
            },
            {
                "verse_number": 3,
                "slok": "यथा प्रदीप्तपावक्रे पतङ्गो म्रियते ध्रुवम् ।\nतथा कामविमूढात्मा नरकेष्ववसीदति ॥",
                "transliteration": "yathā pradīptapāvakre pataṅgo mriyate dhruvam |\ntathā kāmavimūḍhātmā narakeṣvavasīdati ||",
                "meaning_mr": "ज्याप्रमाणे पेटलेल्या अग्नीवर मोहाने झेप घेणारा पतंग जळून खाक होतो, त्याचप्रमाणे वासनेच्या आहारी गेलेला अज्ञानी मनुष्य स्वतः नरकाच्या खाईत पडतो.",
                "meaning_hi": "जैसे जलती आग के आकर्षण में पतंगा जलकर भस्म हो जाता है, वैसे ही वासना के वशीभूत मूर्ख मनुष्य स्वयं नरक के गर्त में गिरता है।",
                "meaning_en": "Just as a moth hurls itself into blazing flames and perishes, so does the soul blinded by uncontrolled lust plunge itself into perdition."
            },
            {
                "verse_number": 4,
                "slok": "तस्मात्सर्वप्रयत्नेन पापकर्म विवर्जयेत् ।\nधर्ममेव निषेवेत यदीच्छेच्छ्रेय आत्मनः ॥",
                "transliteration": "tasmātsarvaprayatnena pāpakarma vivarjayet |\ndharmameva niṣeveta yadīcchecchreya ātmanaḥ ||",
                "meaning_mr": "म्हणून जर मनुष्याला स्वतःचे खरे कल्याण आणि मुक्ती हवी असेल, तर त्याने सर्व प्रयत्नांनी पापाचा त्याग करावा आणि धर्माचे नित्य आचरण करावे.",
                "meaning_hi": "अतः यदि मनुष्य अपना वास्तविक कल्याण चाहता है, तो उसे हर संभव प्रयास से पाप कर्मों का त्याग कर धर्म का ही आचरण करना चाहिए।",
                "meaning_en": "Therefore, with all one's might, one must shun wicked deeds and steadfastly adhere to Dharma if one genuinely desires spiritual peace and auspiciousness."
            }
        ]
    },
    {
        "chapter_number": 5,
        "name_sanskrit": "कर्मचिह्ननिदर्शनम्",
        "name_mr": "पापांची चिन्हे आणि कर्मविपाक",
        "name_hi": "पापों के चिह्न और कर्मविपाक",
        "name_en": "The Manifestation and Signs of Sins",
        "summary_mr": "पूर्वजन्मातील पापकर्मांच्या प्रभावाने या जन्मात मिळणारे व्याधी, रोग, व्यंग आणि विविध प्राणी-पक्ष्यांच्या निकृष्ट योनींचे विवरण.",
        "summary_hi": "पूर्वजन्म के पापों के कारण उत्पन्न होने वाले असाध्य रोग, शारीरिक विकृतियाँ तथा विभिन्न पशु-पक्षी योनियों में जन्म का गूढ़ रहस्य।",
        "summary_en": "How past negative karmas manifest in subsequent lives as bodily ailments, afflictions, poverty, and descent into sub-human forms.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "कर्मणा जायते जन्तुः कर्मणैव प्रलीयते ।\nसुखं दुःखं भयं क्षेमं कर्मणैवाभिपद्यते ॥",
                "transliteration": "karmaṇā jāyate jantuḥ karmaṇaiva pralīyate |\nsukhaṃ duḥkhaṃ bhayaṃ kṣemaṃ karmaṇaivābhipadyate ||",
                "meaning_mr": "जीवाचा जन्म कर्मानेच होतो, त्याचा अंत कर्मानेच होतो; सुख, दुःख, भय आणि कल्याण हे सर्व कर्माच्याच नियमाने प्राप्त होते.",
                "meaning_hi": "जीव अपने कर्मों से ही जन्म लेता है और कर्मों से ही विलीन होता है; सुख, दुःख, भय और कल्याण सब कर्म के अधीन ही मिलते हैं।",
                "meaning_en": "By karma an embodied creature takes birth, and by karma it dissolves; happiness, distress, fear, and security are all distributed by the immutable law of karma."
            },
            {
                "verse_number": 2,
                "slok": "ब्रह्महा क्षयरोगी स्यात् सुरापः श्यावदन्तकः ।\nसुवर्णहर्ता कुनखी दुश्चर्मा गुरुतल्पगः ॥",
                "transliteration": "brahmahā kṣayarogī syāt surāpaḥ śyāvadantakaḥ |\nsuvarṇahartā kunakhī duścarmā gurutalpagaḥ ||",
                "meaning_mr": "पूर्वजन्मी ज्ञानी पुरुषाचा घात करणारा क्षयरोगी होतो, मद्यपान करणारा काळ्या दातांचा होतो, सुवर्ण चोरणाऱ्याची नखे विकृत होतात आणि गुरुपत्नीगमन करणारा दुर्धर त्वचारोगी होतो.",
                "meaning_hi": "पूर्वजन्म में हत्या करने वाला क्षयरोगी होता है, मदिरा पीने वाले के दांत काले होते हैं, सुवर्ण चुराने वाले के नाखून विकृत होते हैं और गुरुद्रोही को चर्मरोग होता है।",
                "meaning_en": "The slayer of sages is afflicted with consumption, the drinker of wine with blackened teeth, the stealer of gold with ruined nails, and the violator of the teacher's trust with chronic skin diseases."
            },
            {
                "verse_number": 3,
                "slok": "एवं कर्मविशेषेण जायन्ते विकृता नराः ।\nजडमूकान्धबधिरा हीनाङ्गाश्च तथापरे ॥",
                "transliteration": "evaṃ karmaviśeṣeṇa jāyante vikṛtā narāḥ |\njaḍamūkāndhabadhirā hīnāṅgāśca tathāpare ||",
                "meaning_mr": "अशा रीतीने पूर्वजन्मातील पापकर्मांच्या प्रभावाने मनुष्य मंदबुद्धी, मुका, आंधळा, बहिरा किंवा अपंग शरीराने जन्माला येतो.",
                "meaning_hi": "इस प्रकार अपने विशिष्ट पाप कर्मों के फल से मनुष्य जड़, मूक, अंधे, बहरे और अंगहीन होकर जन्म लेते हैं।",
                "meaning_en": "Thus, due to particular transgressions in past lives, beings are born foolish, mute, blind, deaf, and afflicted with physical infirmities."
            },
            {
                "verse_number": 4,
                "slok": "प्रायश्चित्तं प्रकुर्वीत पापविशुद्धये नरः ।\nहरिस्मरणमात्रेण सर्वपापैः प्रमुच्यते ॥",
                "transliteration": "prāyaścittaṃ prakurvīta pāpaviśuddhaye naraḥ |\nharismaraṇamātreṇa sarvapāpaiḥ pramucyate ||",
                "meaning_mr": "म्हणून पापांच्या निवृत्तीसाठी मनुष्याने योग्य प्रायश्चित्त करावे; आणि अनन्यभावाने भगवंतांचे नामस्मरण केले असता सर्व पापांतून तत्काळ मुक्ती मिळते.",
                "meaning_hi": "अतः पापों से मुक्ति के लिए मनुष्य को प्रायश्चित्त करना चाहिए; और निष्कपट भाव से श्रीहरि का नामस्मरण करने मात्र से समस्त पाप नष्ट हो जाते हैं।",
                "meaning_en": "Let a person perform sincere penance for purification; and by remembering Lord Hari with a devout heart, one is liberated from all accumulated impurities."
            }
        ]
    },
    {
        "chapter_number": 6,
        "name_sanskrit": "गर्भवासकष्टवर्णनम्",
        "name_mr": "जीवाचा जन्म आणि गर्भवास यातना",
        "name_hi": "जीवात्मा का जन्म और गर्भवास की यातना",
        "name_en": "The Miseries of Conception and Birth",
        "summary_mr": "नरकभोगानंतर जीवाचे मातृगर्भात प्रवेशन, गर्भावस्थेतील तीव्र यातना, भगवंतांची आर्त स्तुती आणि जन्मानंतर मायेच्या प्रभावाने विस्मरण.",
        "summary_hi": "नरक की समाप्ति के पश्चात आत्मा का मातृगर्भ में वास, गर्भ में जीवात्मा द्वारा भगवान की प्रार्थना और जन्म के बाद सांसारिक माया में उलझने का वृत्तांत।",
        "summary_en": "The soul's arduous journey into a mother's womb, its nine months of confinement and prayers to God, and the post-birth veil of worldly illusion.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "शुक्रशोणितसंयोगात् संभूतो गर्भगो भवेत् ।\nकललं प्रथमं मासि द्वितीये पिण्डतां गतः ॥",
                "transliteration": "śukraśoṇitasaṃyogāt saṃbhūto garbhago bhavet |\nkalalaṃ prathamaṃ māsi dvitīye piṇḍatāṃ gataḥ ||",
                "meaning_mr": "स्त्री-पुरुषाच्या संयोगाने जीव मातेच्या गर्भात प्रवेश करतो; पहिल्या महिन्यात द्रवस्वरूप (कलल) आणि दुसऱ्या महिन्यात पिंडस्वरूप धारण करतो.",
                "meaning_hi": "माता-पिता के संयोग से जीवात्मा गर्भ में प्रवेश करता है; पहले मास में वह जल के समान तरल रहता है और दूसरे मास में मांसपिंड का रूप धारण करता है।",
                "meaning_en": "Through parental union, the soul enters the maternal womb; in the first month it forms a fluid nucleus, and in the second month a solid tissue."
            },
            {
                "verse_number": 2,
                "slok": "मातृभुक्तान्नपानेन वर्धते जठरानले ।\nअत्युष्णक्षारसंस्पर्शैः क्लिश्यमानो मुहुर्मुहुः ॥",
                "transliteration": "mātṛbhuktānnapānena vardhate jaṭharānale |\natyuṣṇakṣārasaṃsparśaiḥ kliśyamāno muhurmuhuḥ ||",
                "meaning_mr": "मातेने खाल्लेल्या अन्नाच्या रसाने तो जठराग्नीजवळ वाढतो; अति तिखट, खारट पदार्थांच्या स्पर्शाने त्याला गर्भात अत्यंत असह्य वेदना होतात.",
                "meaning_hi": "माता द्वारा ग्रहण किए गए अन्न के रस से वह जठराग्नि के निकट पलता है; अत्यंत गर्म व तीखे पदार्थों के संपर्क से वह गर्भाशय में निरंतर पीड़ा सहता है।",
                "meaning_en": "Nourished by the essence of whatever the mother consumes, it grows pressed against the digestive fire, severely tormented by caustic, pungent, and salty tastes."
            },
            {
                "verse_number": 3,
                "slok": "स्मरन् पूर्वाणि जन्मानि कृतानि सुकृतानि च ।\nप्रार्थयत्यञ्जलिं बद्ध्वा त्राहि मां मधुसूदन ॥",
                "transliteration": "smaran pūrvāṇi janmāni kṛtāni sukṛtāni ca |\nprārthayatyañjaliṃ baddhvā trāhi māṃ madhusūdana ||",
                "meaning_mr": "गर्भावस्थेत त्याला पूर्वजन्मांतील सर्व कर्मांची आठवण होते; तो दोन्ही हात जोडून करुणा भाकतो: 'हे मधुसूदना! या गर्भवासाच्या बंधनातून माझे रक्षण करा!'",
                "meaning_hi": "गर्भ में उसे अपने पूर्व जन्मों के भले-बुरे कर्म याद आते हैं; वह हाथ जोड़कर प्रार्थना करता है: 'हे मधुसूदन! मुझे इस नरक समान गर्भवास से मुक्त कीजिए!'",
                "meaning_en": "Remembering its previous lives and deeds, the soul folds subtle hands within the womb and implores: 'Protect me, O Lord Madhusudana, from this suffocating prison!'"
            },
            {
                "verse_number": 4,
                "slok": "योनिद्वारेण निष्क्रान्तो मायासंमोहितस्ततः ।\nविस्मरत्यात्मनो ज्ञानं संसारे पुनरेव च ॥",
                "transliteration": "yonidvāreṇa niṣkrānto māyāsaṃmohitastataḥ |\nvismaratyātmano jñānaṃ saṃsāre punareva ca ||",
                "meaning_mr": "जन्म होताच बाह्य जगातील मायेच्या हवेने तो मोहित होतो, गर्भातील आत्मज्ञान विसरतो आणि पुन्हा संसाराच्या मोहात अडकतो.",
                "meaning_hi": "जन्म लेते ही वह संसार की माया से मोहित हो जाता है, गर्भ के ज्ञान को विस्मृत कर देता है और पुनः सांसारिक मोहजाल में फंस जाता है।",
                "meaning_en": "Upon emerging into the world, it is instantly ensnared by the mystic potency of Maya; it forgets its divine contemplation and is swept away by worldly cravings."
            }
        ]
    },
    {
        "chapter_number": 7,
        "name_sanskrit": "बभ्रुवाहनोपाख्यानम्",
        "name_mr": "राजा बभ्रुवाहन आख्यान व प्रेतयोनी निवारण",
        "name_hi": "राजा बभ्रुवाहन आख्यान और प्रेतयोनि से मुक्ति",
        "name_en": "King Babhruvahana and Redemption of the Ghost",
        "summary_mr": "राजा बभ्रुवाहनाला वनात भेटलेला भुकेला प्रेत, प्रेतयोनीची कारणे आणि योग्य श्राद्ध-पिंडदानाने त्याला प्राप्त झालेली दिव्य मुक्ती.",
        "summary_hi": "राजा बभ्रुवाहन की कथा, जिसमें प्रेतयोनि में पड़े एक जीव को राजा द्वारा विधिपूर्वक श्राद्ध करने से दिव्य मोक्ष प्राप्त होता है।",
        "summary_en": "The narrative of King Babhruvahana who encounters an agonizing spirit in the forest, and by performing the sacred funeral rites, liberates it to the heavenly realms.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "बभ्रुवाहननाम्ना तु राजा परमधार्मिकः ।\nमृगयां विचरंस्तूर्णं ददर्श गहनं वनम् ॥",
                "transliteration": "babhruvāhananāmnā tu rājā paramadhārmikaḥ |\nmṛgayāṃ vicaraṃstūrṇaṃ dadarśa gahanaṃ vanam ||",
                "meaning_mr": "बभ्रुवाहन नावाचा एक परम धर्मनिष्ठ राजा एके दिवशी शिकारीसाठी फिरत असताना एका अतिशय घनदाट वनात पोहोचला.",
                "meaning_hi": "बभ्रुवाहन नाम का एक अत्यंत धर्मात्मा राजा शिकार के लिए घूमते हुए एक दिन अत्यंत घने और बीहड़ जंगल में जा पहुँचा।",
                "meaning_en": "There was a virtuous king named Babhruvahana who, wandering on a hunt, penetrated deep into a solitary forest wilderness."
            },
            {
                "verse_number": 2,
                "slok": "तत्रापश्यन्महाकायं प्रेतं क्षुत्तृषयार्दितम् ।\nकङ्कालमात्रदेहाभं विरूपाक्षं भयानकम् ॥",
                "transliteration": "tatrāpaśyanmahākāyaṃ pretaṃ kṣuttṛṣayārditam |\nkaṅkālamātradehābhaṃ virūpākṣaṃ bhayānakam ||",
                "meaning_mr": "तिथे त्याने भूक आणि तहानेने व्याकूळ झालेला, केवळ हाडांचा सांगाडा उरलेला आणि अतिशय भयंकर दिसणारा एक प्रेत पाहिला.",
                "meaning_hi": "वहाँ उसने भूख-प्यास से तड़पते हुए, केवल हड्डियों का ढांचा बने हुए एक भयंकर प्रेत को देखा।",
                "meaning_en": "There he beheld a dreadful ghost, reduced to a mere skeleton, tormented with insatiable hunger and thirst, with hollow eyes and ghastly visage."
            },
            {
                "verse_number": 3,
                "slok": "प्रेत उवाच -\nअपुत्रस्य ह्यश्राद्धस्य प्रेतभावो मयार्जितः ।\nत्वत्प्रसादादहं मुच्ये श्राद्धं कुरु महीपते ॥",
                "transliteration": "preta uvāca -\naputrasya hyaśrāddhasya pretabhāvo mayārjitaḥ |\ntvatprasādādahaṃ mucye śrāddhaṃ kuru mahīpate ||",
                "meaning_mr": "तो प्रेत म्हणाला: हे राजन! माझा कोणी पुत्र नसल्यामुळे आणि माझ्यासाठी श्राद्ध न झाल्यामुळे मला ही प्रेतयोनी मिळाली; आपण कृपा करून माझ्यासाठी श्राद्ध करून मला मुक्त करा.",
                "meaning_hi": "प्रेत बोला: हे राजन्! कोई पुत्र न होने और श्राद्ध-तर्पण न होने के कारण मुझे यह दुर्गति मिली है; आप कृपा करके मेरा श्राद्ध कर मुझे इस प्रेतभाव से उबारें।",
                "meaning_en": "The spirit wept: O King! Having left no son behind and receiving no funeral libations, I wander in this torment; pray perform my obsequies that I may be released!"
            },
            {
                "verse_number": 4,
                "slok": "तच्छ्रुत्वा नृपतिः श्रेष्ठः चक्रे श्राद्धं विधावतः ।\nततस्त्यक्त्वा प्रेतभावं स ययौ त्रिदिवं शुभम् ॥",
                "transliteration": "tacchrutvā nṛpatiḥ śreṣṭhaḥ cakre śrāddhaṃ vidhāvataḥ |\ntatastyaktvā pretabhāvaṃ sa yayau tridivaṃ śubham ||",
                "meaning_mr": "त्याचे करुण बोलणे ऐकून दयाळू राजाने शास्त्रोक्त पद्धतीने त्याचे श्राद्ध केले; त्या पुण्याने प्रेतयोनीतून मुक्त होऊन तो जीव विमानाने स्वर्गात गेला.",
                "meaning_hi": "उसकी करुण पुकार सुनकर दयालु राजा ने विधिपूर्वक उसका श्राद्ध किया; जिससे वह प्रेतयोनि से छूटकर दिव्य विमान में बैठकर स्वर्गलोक को चला गया।",
                "meaning_en": "Hearing this plea, the compassionate monarch performed the sacred funeral rites as ordained; freed instantly from ghostly existence, the spirit mounted a celestial chariot to heaven."
            }
        ]
    },
    {
        "chapter_number": 8,
        "name_sanskrit": "और्ध्वदेहिकदानविधानम्",
        "name_mr": "और्ध्वदेहिक दाने आणि वैतरणी तरण",
        "name_hi": "और्ध्वदेहिक दान और वैतरणी तरण",
        "name_en": "Sacred Gifts for the Dying and Crossing Vaitarani",
        "summary_mr": "गोदान, भूमिदान, सुवर्णदान, वस्त्रदान, तीळदान इत्यादी महादानांचे सामर्थ्य ज्यामुळे यममार्ग सुगम होतो आणि वैतरणी नदी सुखेनैव पार करता येते.",
        "summary_hi": "मृत्यु के समय और उपरांत किए जाने वाले दस महादान (गोदान, तिलदान, स्वर्णदान आदि) जिनकी कृपा से जीवात्मा वैतरणी को सरलता से पार कर जाता है।",
        "summary_en": "The sacred ten gifts, especially the gifting of a cow (Godan), grain, land, and sesame seeds, which empower the soul to effortlessly cross the River Vaitarani.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "दश दानानि वक्ष्यामि यैर्मुच्यन्ते यमाध्वनः ।\nतिला लोहं हिरण्यं च कार्पासं लवणं तथा ॥\nधान्यं क्षितिस्तथा गावो वस्त्रं छागस्तथैव च ॥",
                "transliteration": "daśa dānāni vakṣyāmi yairmucyante yamādhvanaḥ |\ntilā lohaṃ hiraṇyaṃ ca kārpāsaṃ lavaṇaṃ tathā ||\ndhānyaṃ kṣitistathā gāvo vastraṃ chāgastathaiva ca ||",
                "meaning_mr": "यममार्गावरील संकटातून मुक्ती मिळण्यासाठी शास्त्रोक्त दहा दाने आहेत: तीळ, लोखंड, सोने, कापूस, मीठ, धान्य, जमीन, गाय, वस्त्र आणि छत्र.",
                "meaning_hi": "यममार्ग के संकटों से रक्षा करने वाले दस महादान हैं: तिल, लोहा, स्वर्ण, कपास, नमक, धान्य, भूमि, गौ, वस्त्र और छत्र।",
                "meaning_en": "I shall declare the ten supreme gifts that release the soul from Yama's trail: sesame, iron, gold, cotton, salt, grain, sacred land, a milch cow, garments, and shelter."
            },
            {
                "verse_number": 2,
                "slok": "धेनुर्वैतरणी नाम सर्वपापप्रणाशिनी ।\nदत्ता चेन्मुच्यते जन्तुः वैतरण्या महाभयात् ॥",
                "transliteration": "dhenurvaitaraṇī nāma sarvapāpapraṇāśinī |\ndattā cenmucyate jantuḥ vaitaraṇyā mahābhayāt ||",
                "meaning_mr": "वैतरणी नदी तरून जाण्यासाठी दिलेली सवत्स गाय सर्व पापांचा नाश करते; तिच्या शेपटीचा आधार घेऊन जीव भयानक वैतरणी नदी सुखाने पार करतो.",
                "meaning_hi": "वैतरणी पार करने के निमित्त दी गई गौ समस्त पापों का नाश करती है; उस गोदान के प्रभाव से जीवात्मा वैतरणी के भय से सहज ही मुक्त हो जाता है।",
                "meaning_en": "The gift of a cow dedicated to Vaitarani annuls every transgression; grasping her tail, the soul effortlessly glides across the raging infernal torrent."
            },
            {
                "verse_number": 3,
                "slok": "जीवता यत्कृतं दानं तत्परत्रोपकारकम् ।\nमृते ददाति यः पुत्रः तदप्यक्षय्यमुच्यते ॥",
                "transliteration": "jīvatā yatkṛtaṃ dānaṃ tatparatropakārakam |\nmṛte dadāti yaḥ putraḥ tadapyakṣayyamucyate ||",
                "meaning_mr": "मनुष्याने स्वतःच्या हयातीत केलेले दान परलोकात सर्वात जास्त फळ देते; तसेच मृत्यूनंतर सुपुत्राने श्रद्धेने दिलेले दानही अक्षय्य फलदायी ठरते.",
                "meaning_hi": "जीवितावस्था में मनुष्य जो सत्पात्र दान करता है वह परलोक में सबसे बड़ा सहारा बनता है; और मरणोपरांत सुपुत्र द्वारा दिया गया दान भी अक्षय फल देता है।",
                "meaning_en": "The charity offered by oneself while alive confers highest solace hereafter; yet that which a devoted child offers following departure also bears everlasting fruit."
            }
        ]
    },
    {
        "chapter_number": 9,
        "name_sanskrit": "आतुरसंन्यास-मरणकालविधानम्",
        "name_mr": "मरणासन्न विधी आणि अंत्यविधी",
        "name_hi": "मरणासन्न विधि और अंत्येष्टि संस्कार",
        "name_en": "Rites for the Dying and the Moment of Departure",
        "summary_mr": "अंतसमयी तुळशीपत्र, गंगाजल, भगवद्गीता श्रवण, नारायण स्मरण आणि पार्थिव देहाचे पवित्र अग्नीसंस्कार करण्याचे नियम.",
        "summary_hi": "मृत्यु शय्या पर पड़े व्यक्ति के समीप तुलसी, गंगाजल, गीता पाठ और भगवान के नाम-संकीर्तन का महत्त्व तथा अंतिम संस्कार के नियम।",
        "summary_en": "The sacred rites to be performed as life ebbs away: offering Ganga water, placing sacred Tulasi, chanting the holy names, and conducting the cremation.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "मरणे समनुप्राप्ते गोमयेनोपलेपिते ।\nकुशदर्भांस्तथास्तीर्य स्थापयेत्तु वसुन्धराम् ॥",
                "transliteration": "maraṇe samanuprāpte gomayenopalepite |\nkuśadarbhāṃstathāstīrya sthāpayettu vasundharām ||",
                "meaning_mr": "मृत्यु जवळ आल्याचे समजताच भूमीवर गोमूत्र-गोमयाने लेपन करून त्यावर दर्भ आणि तीळ पसरावेत आणि व्यक्तीला भूमीवर शांतपणे ठेवावे.",
                "meaning_hi": "मृत्यु का समय निकट जान भूमि को गोबर से लीपकर उस पर कुश और काले तिल बिछाकर मरणासन्न व्यक्ति को भूमि पर लिटाना चाहिए।",
                "meaning_en": "When departure draws near, the ground should be cleansed with sacred earth and cow dung, spread with Darbha grass and sesame, and the body placed upon mother earth."
            },
            {
                "verse_number": 2,
                "slok": "तुलसीसन्निधौ मृत्युः गङ्गातोयस्य मञ्जनम् ।\nगीतानामस्मरणं च मुक्तिदं नात्र संशयः ॥",
                "transliteration": "tulasīsannidhau mṛtyuḥ gaṅgātoyasya mañjanam |\ngītānāmasmaraṇaṃ ca muktidaṃ nātra saṃśayaḥ ||",
                "meaning_mr": "तुळशीच्या सान्निध्यात मरण, मुखात गंगाजल आणि तुळशीपत्र, आणि कानात श्रीमद्भगवद्गीता व भगवंतांचे नामस्मरण जीवात्माला मोक्ष देते, यात संशय नाही.",
                "meaning_hi": "तुलसीदल के सान्निध्य में मृत्यु, मुख में गंगाजल की बूंदें, गीता का पाठ और 'हरि' नाम का श्रवण निश्चित रूप से मोक्ष प्रदान करता है।",
                "meaning_en": "Passing away in the presence of sacred Tulasi, receiving drops of holy Ganga water, and hearing the Bhagavad Gita and Hari's name ensures liberation without doubt."
            },
            {
                "verse_number": 3,
                "slok": "अन्ते नारायणं स्मृत्वा यस्त्यजेत् स्वकलेवरम् ।\nस याति परमां सिद्धिं पुनरावृत्तिवर्जिताम् ॥",
                "transliteration": "ante nārāyaṇaṃ smṛtvā yastyajet svakalevaram |\nsa yāti paramāṃ siddhiṃ punarāvṛttivarjitām ||",
                "meaning_mr": "अंतकाळी केवळ 'नारायण' या दिव्य नामाचे स्मरण करून जो मनुष्य देह सोडतो, तो जन्म-मरणाच्या फेऱ्यातून सुटून परमगतीला प्राप्त होतो.",
                "meaning_hi": "अंतिम क्षण में भगवान 'नारायण' का स्मरण करते हुए जो देह त्याग करता है, वह आवागमन से मुक्त होकर परम पद को प्राप्त करता है।",
                "meaning_en": "Whoever sheds the mortal coil with the holy name 'Narayana' residing in heart and mind attains the supreme abode, never to return to worldly rebirth."
            }
        ]
    },
    {
        "chapter_number": 10,
        "name_sanskrit": "अस्थिसंचयन-पिण्डदानविधिः",
        "name_mr": "अस्थिसंचयन विधी आणि तीर्थस्नान",
        "name_hi": "अस्थि संचयन और तीर्थ विसर्जन",
        "name_en": "The Collecting and Immersing of Bones in Sacred Rivers",
        "summary_mr": "दहनानंतर अस्थी गोळा करणे, त्या गंगा किंवा पवित्र तीर्थक्षेत्रात विसर्जित करणे आणि त्यामुळे मृतात्म्याला होणारा शाश्वत आनंद.",
        "summary_hi": "शवदाह के उपरांत पवित्र अस्थियों का संचयन और उन्हें गंगा अथवा पवित्र नदियों में विसर्जन की विधि जिससे पितरों को परम तृप्ति मिलती है।",
        "summary_en": "The sacred collection of calcined bones and their ceremonial immersion in holy rivers like the Ganga, bestowing liberation and eternal peace.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "तृतीयेऽहनि कर्तव्यं अस्थिसञ्चयनं शुभम् ।\nगङ्गाम्भसि विसृज्यन्ते यावदस्थीनि देहिनः ॥\nतावद्वर्षसहस्राणि स्वर्गलोके महीयते ॥",
                "transliteration": "tṛtīye'hani kartavyaṃ asthisañcayanaṃ śubham |\ngaṅgāmbhasi visṛjyante yāvadasthīni dehinaḥ ||\ntāvadvarṣasahasrāṇi svargaloke mahīyate ||",
                "meaning_mr": "तिसऱ्या किंवा चौथ्या दिवशी पवित्र अस्थिसंचयन करावे; मृत व्यक्तीची अस्थी जोपर्यंत गंगेच्या पावन पाण्यात राहते, तोपर्यंत हजारो वर्षे तो स्वर्गात आनंद भोगतो.",
                "meaning_hi": "दाह संस्कार के तीसरे दिन अस्थियों का संचयन करना चाहिए; मनुष्य की अस्थियाँ जब तक गंगाजल में रहती हैं, तब तक वह हजारों वर्षों तक स्वर्ग में सम्मानित रहता है।",
                "meaning_en": "On the third day the bones should be collected reverently; as long as even a fragment of the bone rests in Ganga's waters, the soul is honored in heaven for millennia."
            },
            {
                "verse_number": 2,
                "slok": "गङ्गा गङ्गेति यो ब्रूयात् योजनानां शतैरपि ।\nमुच्यते सर्वपापेभ्यो विष्णुलोकं स गच्छति ॥",
                "transliteration": "gaṅgā gaṅgeti yo brūyāt yojanānāṃ śatairapi |\nmucyate sarvapāpebhyo viṣṇulokaṃ sa gacchati ||",
                "meaning_mr": "शेकडो मैल दूर राहूनही जो मनुष्य श्रद्धेने 'गंगा! गंगा!' असा जयघोष करतो, तो सर्व पापांतून मुक्त होऊन वैकुंठाला जातो.",
                "meaning_hi": "सैकड़ों योजन दूर रहकर भी जो मनुष्य 'गंगा-गंगा' का स्मरण करता है, वह समस्त पापों से मुक्त होकर विष्णुलोक को प्राप्त होता है।",
                "meaning_en": "Even from hundreds of leagues away, whoever chants 'Ganga, Ganga' with a pure heart is cleansed of all transgressions and attains Vishnu's realm."
            }
        ]
    },
    {
        "chapter_number": 11,
        "name_sanskrit": "एकोद्दिष्ट-दशगात्रविधानम्",
        "name_mr": "एकोद्दिष्ट व दशगात्र विधी",
        "name_hi": "एकोद्दिष्ट और दशगात्र विधान",
        "name_en": "The Ten-Days' Ceremonies and Formation of the Subtle Body",
        "summary_mr": "पहिल्या दहा दिवसांत दररोज एक पिंडदान, ज्यामुळे जीवाचे नवे वायुरूप शरीर तयार होते आणि अकरा-बारा दिवसांच्या श्राद्धाचे महत्त्व.",
        "summary_hi": "मृत्यु के पश्चात् प्रथम दस दिनों में दिए जाने वाले पिंडों से जीवात्मा के सूक्ष्म शरीर का निर्माण और दशगात्र विधी का विधान।",
        "summary_en": "Daily offerings of rice balls (pinda) during the first ten days, which sequentially construct a subtle vehicle for the soul's journey.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "दशपिण्डाः प्रदातव्याः दशाहं तु दिने दिने ।\nयेन पिण्डेन निष्पन्नं शरीरं यातनामयम् ॥",
                "transliteration": "daśapiṇḍāḥ pradātavyāḥ daśāhaṃ tu dine dine |\nyena piṇḍena niṣpannaṃ śarīraṃ yātanāmayam ||",
                "meaning_mr": "मृत्यूनंतर पहिल्या दहा दिवसांत दररोज एक असे दहा पिंड द्यावेत; या पिंडदानाने जीवात्म्याचे परलोकातील सूक्ष्म शरीर तयार होते.",
                "meaning_hi": "मृत्यु के बाद दस दिनों तक प्रतिदिन एक-एक पिंडदान करना चाहिए; इन पिंडों से जीवात्मा का नवीन सूक्ष्म शरीर निर्मित होता है।",
                "meaning_en": "During the ten days following death, ten rice balls (pindas) must be offered daily; through these offerings, a subtle bodily vehicle is assembled for the soul."
            },
            {
                "verse_number": 2,
                "slok": "प्रथमेन शिरो निष्पन्नं द्वितीये नेत्रकर्णकौ ।\nतृतीये कण्ठहृदयं दशमेन तृप्तिमाप्नुयात् ॥",
                "transliteration": "prathamena śiro niṣpannaṃ dvitīye netrakarṇakau |\ntṛtīye kaṇṭhahṛdayaṃ daśamena tṛptimāpnuyāt ||",
                "meaning_mr": "पहिल्या पिंडाने मस्तक, दुसऱ्याने डोळे-कान, तिसऱ्याने मान व छाती अशी निर्मिती होते, आणि दहाव्या पिंडाने सूक्ष्म देह पूर्ण होऊन तृप्ती मिळते.",
                "meaning_hi": "प्रथम पिंड से सिर, द्वितीय से आँख-कान, तृतीय से कंठ-हृदय बनते हैं और दसवें पिंड से सूक्ष्म शरीर पूर्ण होकर तृप्त हो जाता है।",
                "meaning_en": "By the first pinda the head is formed, by the second the eyes and ears, by the third the neck and heart, and by the tenth the entire subtle frame is completed."
            }
        ]
    },
    {
        "chapter_number": 12,
        "name_sanskrit": "एकादशाह-द्वादशाहश्राद्धविधानम्",
        "name_mr": "एकादशाह आणि द्वादशाह श्राद्ध",
        "name_hi": "एकादशाह और द्वादशाह श्राद्ध",
        "name_en": "The Eleventh and Twelfth Day Observances",
        "summary_mr": "अकराव्या दिवशी घराची शुद्धी, वृषोत्सर्ग विधी, बाराव्या दिवशी पाथेय श्राद्ध आणि सपिंडीकरणाची पूर्वतयारी.",
        "summary_hi": "ग्यारहवें दिन गृहशुद्धि, ब्राह्मण भोजन, वृषोत्सर्ग तथा बारहवें दिन यममार्ग के पाथेय (मार्गव्यय) श्राद्ध का विधान।",
        "summary_en": "The rites of the eleventh day for house purification, setting free a sacred bull (Vrishotsarga), and provisioning the spirit for its one-year trek.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "एकादशेऽहनि प्राप्ते गृहशुद्धिं समाचरेत् ।\nवृषोत्सर्गः प्रकर्तव्यः पितॄणां तारणाय वै ॥",
                "transliteration": "ekādaśe'hani prāpte gṛhaśuddhiṃ samācaret |\nvṛṣotsargaḥ prakartavyaḥ pitṝṇāṃ tāraṇāya vai ||",
                "meaning_mr": "अकराव्या दिवशी संपूर्ण घराची शुद्धी करावी आणि पितरांच्या उद्धारासाठी शास्त्रोक्त वृषोत्सर्ग (बैल सोडण्याचा विधी) करावा.",
                "meaning_hi": "ग्यारहवें दिन घर की पूर्ण शुद्धि करनी चाहिए और पूर्वजों के उद्धार हेतु शास्त्रोक्त वृषोत्सर्ग का अनुष्ठान करना चाहिए।",
                "meaning_en": "On the eleventh day the house must be purified, and for the upliftment of ancestors, the sacred release of the bull (Vrishotsarga) should be observed."
            },
            {
                "verse_number": 2,
                "slok": "द्वादशेऽहनि यच्छ्राद्धं तद्धि पाथेयमुच्यते ।\nतेन तृप्तो यमपथे याति जीवात्मनो सुखम् ॥",
                "transliteration": "dvādaśe'hani yacchrāddhaṃ taddhi pātheyamucyate |\ntena tṛpto yamapathe yāti jīvātmano sukham ||",
                "meaning_mr": "बाराव्या दिवशी जे श्राद्ध केले जाते ते जीवासाठी यममार्गावरील शिदोरी (पाथेय) ठरते; त्यामुळे तृप्त होऊन जीव पुढची वाटचाल सुखाने करतो.",
                "meaning_hi": "बारहवें दिन जो श्राद्ध किया जाता है, वह यममार्ग की यात्रा का संबल (पाथेय) बनता है; उससे तृप्त होकर जीव सुखपूर्वक आगे बढ़ता है।",
                "meaning_en": "The rites of the twelfth day supply the travel sustenance (patheya) for the departed spirit, empowering it to traverse the long journey with ease."
            }
        ]
    },
    {
        "chapter_number": 13,
        "name_sanskrit": "सपिण्डीकरणश्राद्धविधानम्",
        "name_mr": "सपिंडीकरण विधी व पितृलोकात प्रवेश",
        "name_hi": "सपिंडीकरण विधान और पितृलोक में प्रवेश",
        "name_en": "The Unification Rite with Ancestors (Sapindikarana)",
        "summary_mr": "प्रेतभाव संपवून पितृगणात प्रवेश मिळवून देणारा अत्यंत पवित्र सपिंडीकरण संस्कार. या विधीनंतर मृतात्मा देवपितरांच्या पंगतीत बसतो.",
        "summary_hi": "प्रेत अवस्था से मुक्त होकर पितरों की श्रेणी में सम्मिलित होने वाला सपिंडीकरण संस्कार, जिसके उपरांत जीव पितृलोक को प्राप्त होता है।",
        "summary_en": "The profound ceremony uniting the departed soul with three generations of ancestral pitris, freeing it forever from ghostly isolation.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "सपिण्डीकरणादूर्ध्वं प्रेतो मुञ्चति प्रेतताम् ।\nपितृलोकं समासाद्य पितृभिः सह मोदते ॥",
                "transliteration": "sapiṇḍīkaraṇādūrdhvaṃ preto muñcati pretatām |\npitṛlokaṃ samāsādya pitṛbhiḥ saha modate ||",
                "meaning_mr": "सपिंडीकरण विधी संपन्न झाल्यानंतर जीव प्रेतत्वाचा त्याग करतो आणि पितृलोकात जाऊन आपल्या पूर्वजांसोबत आनंदाने राहतो.",
                "meaning_hi": "सपिंडीकरण श्राद्ध के उपरांत जीवात्मा प्रेतभाव से पूर्णतः मुक्त होकर पितृलोक में अपने पूर्वजों के साथ निवास करता है।",
                "meaning_en": "Following the sacred Sapindikarana rite, the departed is freed forever from ghostly distress and joins the ancestral forebears in the realm of the Pitris."
            },
            {
                "verse_number": 2,
                "slok": "संयोज्य पितृभिः सार्धं पिण्डमेकं त्रिधा कृतम् ।\nपितृलोकमवाप्नोति नात्र कार्या विचारणा ॥",
                "transliteration": "saṃyojya pitṛbhiḥ sārdhaṃ piṇḍamekaṃ tridhā kṛtam |\npitṛlokamavāpnoti nātra kāryā vicāraṇā ||",
                "meaning_mr": "पितरांच्या तीन पिंडांशी नवीन जीवाच्या पिंडाचे मिलन केले असता जीव निःसंशय पितृलोकाला प्राप्त होतो.",
                "meaning_hi": "पितरों के पिंडों के साथ जब उस जीव के पिंड का शास्त्रोक्त सम्मिलन होता है, तो वह अवश्य ही पितृलोक को प्राप्त करता है।",
                "meaning_en": "When the offering for the departed is ceremonially merged with the offerings of three ancestral generations, the soul ascends directly to the ancestral heavens."
            }
        ]
    },
    {
        "chapter_number": 14,
        "name_sanskrit": "धर्मराजपुरी-सौम्यमार्गवर्णनम्",
        "name_mr": "धर्मराजांची यमपुरी व चार द्वारे",
        "name_hi": "धर्मराज की यमपुरी और चार द्वार",
        "name_en": "The Four Gates of the City of the King of Justice",
        "summary_mr": "यमराजांच्या दिव्य नगराचे चार भव्य दरवाजे: पूर्वेचे, उत्तरेचे आणि पश्चिमेचे द्वार पुण्यवान, दानी व तपस्वी लोकांसाठी; आणि दक्षिणेचे द्वार पापी लोकांसाठी.",
        "summary_hi": "धर्मराज की दिव्य नगरी के चार द्वारों का वर्णन, जहां पूर्व, उत्तर और पश्चिम द्वार से पुण्यात्माएं सम्मानपूर्वक प्रवेश करती हैं।",
        "summary_en": "The celestial architectural description of Dharmaraja's city with four magnificent gates, through which virtuous souls enter surrounded by divine honors.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "चतुर्द्वारा समायुक्ता धर्मराजपुरी शुभा ।\nविशन्ति पुण्यात्मानस्तु पूर्वोत्तरैस्तथापरैः ॥",
                "transliteration": "caturdvārā samāyuktā dharmarājapurī śubhā |\nviśanti puṇyātmānastu pūrvottaraistathāparaiḥ ||",
                "meaning_mr": "धर्मराजांची विशाल पुरी चार महाद्वारांनी सुशोभित आहे; पूर्व, उत्तर आणि पश्चिम या तीन द्वारे पुण्यात्मे अत्यंत सन्मानाने प्रवेश करतात.",
                "meaning_hi": "धर्मराज यम की दिव्य नगरी में चार भव्य द्वार हैं; पूर्व, उत्तर और पश्चिम द्वारों से पुण्यात्मा जन सम्मानपूर्वक प्रवेश करते हैं।",
                "meaning_en": "The celestial city of the King of Justice is adorned with four grand portals; through the eastern, northern, and western gates, the virtuous enter amidst divine adulation."
            },
            {
                "verse_number": 2,
                "slok": "दक्षिणेन प्रविशन्ति पापिष्ठाः क्लेशभागिनः ।\nधार्मिकाः सुखमायान्ति विमानैः सूर्यसन्निभैः ॥",
                "transliteration": "dakṣiṇena praviśanti pāpiṣṭhāḥ kleśabhāginaḥ |\ndhārmikāḥ sukhamāyānti vimānaiḥ sūryasannibhaiḥ ||",
                "meaning_mr": "केवळ दक्षिण द्वारातून पापी लोक यातना भोगत प्रवेश करतात; तर धर्मात्मे सूर्यसम तेजस्वी विमानांतून देवांसारखे सुखपूर्वक तिथे येतात.",
                "meaning_hi": "केवल दक्षिणी द्वार से पापी लोग यातना भोगते हुए प्रवेश करते हैं; जबकि धर्मात्मा जन सूर्य के समान कांतिवान दिव्य विमानों में सुखपूर्वक आते हैं।",
                "meaning_en": "Only through the grim southern gate do the sinful pass in torment; whereas the righteous arrive upon shining chariots like the sun, attended by celestial music."
            }
        ]
    },
    {
        "chapter_number": 15,
        "name_sanskrit": "पुण्यकृतांगतिवर्णनम्",
        "name_mr": "पुण्यवानांची गती व स्वर्गीय सुख",
        "name_hi": "पुण्यवानों की गति और स्वर्गीय सुख",
        "name_en": "The Exalted Destiny and Rebirth of the Righteous",
        "summary_mr": "सत्यवादी, परोपकारी, आई-वडिलांची सेवा करणारे आणि भगवद्भक्त यांच्या दिव्य लोकांची प्राप्ती आणि उत्तम कुळात जन्म होण्याचे वर्णन.",
        "summary_hi": "सत्यवादी, परोपकारी, माता-पिता के सेवक तथा ईश्वरभक्त मनुष्यों को मिलने वाले दिव्य लोक, विमान और उत्तम कुल में सुखद जन्म का विवरण।",
        "summary_en": "The resplendent reward of truthful, charitable, and devoted humans: residence in heavenly realms and rebirth in noble, spiritual households.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "ये नरा धर्मनिरताः परोपकारिणः सदा ।\nमातृपितृरता नित्यं ते यान्ति परमां गतिम् ॥",
                "transliteration": "ye narā dharmaniratāḥ paropakāriṇaḥ sadā |\nmātṛpitṛratā nityaṃ te yānti paramāṃ gatim ||",
                "meaning_mr": "जे मनुष्य नेहमी धर्मात तत्पर असतात, सदैव परोपकार करतात आणि माता-पित्याची भक्तीभावाने सेवा करतात, त्यांना परम स्वर्गीय गती प्राप्त होते.",
                "meaning_hi": "जो मनुष्य धर्म में निष्ठावान, सदैव दूसरों का उपकार करने वाले और माता-पिता के आज्ञाकारी सेवक होते हैं, वे परम गति को प्राप्त होते हैं।",
                "meaning_en": "Those who abide faithfully in Dharma, dedicate themselves to altruism, and lovingly honor their parents attain the exalted celestial stations."
            },
            {
                "verse_number": 2,
                "slok": "शुचीनां श्रीमतां गेहे योगभ्रष्टोऽभिजायते ।\nपुनस्तत्र समासाद्य योगं मोक्षमवाप्नुयात् ॥",
                "transliteration": "śucīnāṃ śrīmatāṃ gehe yogabhraṣṭo'bhijāyate |\npunastatra samāsādya yogaṃ mokṣamavāpnuyāt ||",
                "meaning_mr": "असे पुण्यवान जीव स्वर्गसुख भोगल्यानंतर या भूलोकावर पवित्र, सदाचारी आणि समृद्ध कुळात जन्म घेतात, आणि आत्मसाधना पूर्ण करून मोक्ष मिळवतात.",
                "meaning_hi": "ऐसे पुण्यात्मा स्वर्ग का सुख भोगकर पृथ्वी पर पवित्र और श्रीमान कुल में जन्म लेते हैं तथा अपनी साधना पूरी कर मोक्ष प्राप्त करते हैं।",
                "meaning_en": "Having enjoyed celestial delights, such noble souls take rebirth in families of pure, upright, and spiritually enlightened souls, easily fulfilling their path to liberation."
            }
        ]
    },
    {
        "chapter_number": 16,
        "name_sanskrit": "मोक्षधर्मनिरूपणम्",
        "name_mr": "आत्मज्ञान, मोक्षधर्म व ग्रंथ फलश्रुती",
        "name_hi": "आत्मज्ञान, मोक्षधर्म और ग्रंथ फलश्रुति",
        "name_en": "The Eternal Law of Liberation and Supreme Knowledge",
        "summary_mr": "बाह्य अवडंबरापेक्षा अंतरीच्या आत्मज्ञानाचे महत्त्व. 'मी ब्रह्म आहे' हा बोध, सर्व जीवात ईश्वराचे दर्शन, संसारातून मुक्ती आणि गरुड पुराणाच्या श्रवणाचे फळ.",
        "summary_hi": "केवल कर्मकांड नहीं बल्कि आत्मज्ञान ही मोक्ष का मूल साधन है। आत्मा की अमरता, ब्रह्मज्ञान और गरुड़ पुराण के पठन-श्रवण का परम कल्याणकारी फल।",
        "summary_en": "The supreme revelation of Self-knowledge as the sole key to ultimate liberation beyond all rituals, realizing Brahman within, and the blessings of reading Garuda Purana.",
        "verses": [
            {
                "verse_number": 1,
                "slok": "न मुक्ताः कर्ममात्रेण न च वेदाध्ययनेन वा ।\nज्ञानेनैव विमुच्यन्ते नान्यथा मुक्तिरिष्यते ॥",
                "transliteration": "na muktāḥ karmamātreṇa na ca vedādhyayanena vā |\njñānenaiva vimucyante nānyathā muktiriṣyate ||",
                "meaning_mr": "केवळ बाह्य कर्मकांडाने किंवा वेदांच्या केवळ वाचनाने मोक्ष मिळत नाही; तर अंतःकरणात आत्मज्ञान प्रगट झाले कीच मुक्ती मिळते, याशिवाय दुसरा मार्ग नाही.",
                "meaning_hi": "केवल बाह्य कर्मकांड या केवल वेदपाठ से मुक्ति नहीं मिलती; वास्तविक आत्मज्ञान से ही परम मोक्ष संभव है, इसके अतिरिक्त अन्य कोई मार्ग नहीं।",
                "meaning_en": "Not by external rituals alone nor mere textual recitation does liberation come; through direct experiential Self-knowledge alone is eternal release attained."
            },
            {
                "verse_number": 2,
                "slok": "अहं ब्रह्मेति यो वेद स मुक्तो नात्र संशयः ।\nसर्वभूतस्थितं देवं पश्यन् याति परां गतिम् ॥",
                "transliteration": "ahaṃ brahmeti yo veda sa mukto nātra saṃśayaḥ |\nsarvabhūtasthitaṃ devaṃ paśyan yāti parāṃ gatim ||",
                "meaning_mr": "'मी सच्चिदानंद आत्मतत्त्व आहे' असा ज्याला साक्षात्कार होतो आणि जो सर्व प्राणिमात्रांमध्ये एकाच परमात्म्याला पाहतो, तो तत्काळ मुक्त होतो.",
                "meaning_hi": "'मैं विशुद्ध आत्मतत्त्व हूँ' ऐसा अनुभव करने वाला और सभी प्राणियों में एक ही परमात्मा को देखने वाला ज्ञानी पुरुष अवश्य मुक्त हो जाता है।",
                "meaning_en": "Whoever directly realizes 'I am the pure divine Consciousness (Brahman)' and perceives the one Lord enshrined in the hearts of all beings is truly emancipated."
            },
            {
                "verse_number": 3,
                "slok": "गरुडस्य पुराणं यः शृणोति श्रावयेत वा ।\nसर्वपापविनिर्मुक्तो विष्णोर्लोके महीयते ॥",
                "transliteration": "garuḍasya purāṇaṃ yaḥ śṛṇoti śrāvayeta vā |\nsarvapāpavinirmukto viṣṇorloke mahīyate ||",
                "meaning_mr": "जो मनुष्य या पवित्र गरुड पुराणाचे नित्य श्रवण अथवा पठण करतो, तो सर्व पापांतून मुक्त होऊन भगवान विष्णूंच्या परम धामात अक्षय्य स्थान मिळवतो.",
                "meaning_hi": "जो मनुष्य इस परम पवित्र गरुड़ पुराण का श्रवण अथवा पठन करता है, वह समस्त पापों से मुक्त होकर भगवान विष्णु के परम धाम को प्राप्त होता है।",
                "meaning_en": "Whoever listens to or recites this sacred Garuda Purana with reverence is absolved of every sin and rejoices eternally in the supreme realm of Lord Vishnu."
            }
        ]
    }
]


def seed_garuda_purana(db_path: Path):
    print(f"🚀 Ingesting Garuda Purana into {db_path}...")
    os.makedirs(db_path.parent, exist_ok=True)
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 1. Update / Insert Book Metadata
    total_chapters = len(GARUDA_CHAPTERS)
    total_verses = sum(len(ch["verses"]) for ch in GARUDA_CHAPTERS)

    cur.execute("""
        INSERT INTO granth_books (
            slug, title_mr, title_hi, title_en,
            subtitle_mr, subtitle_hi, subtitle_en,
            description_mr, description_hi, description_en,
            total_chapters, total_verses, free_chapters, sort_order, is_active
        ) VALUES (
            'garuda-purana',
            'गरुड पुराण सारोद्धार',
            'गरुड़ पुराण सारोद्धार',
            'Garuda Purana Saroddhara',
            'मृत्यूनंतरचा जीवाचा प्रवास आणि कर्माचे गूढ रहस्य',
            'मृत्यु के उपरांत जीवात्मा की गति एवं यमलोक का वर्णन',
            'The Sacred Journey of the Soul, Karma and Moksha',
            'भगवान विष्णू आणि गरुड यांच्यातील संवादरूप पवित्र ग्रंथ, ज्यामध्ये आत्म्याचा प्रवास, कर्मफळ, यमपुरी आणि मोक्षधर्माचे दिव्य मार्गदर्शन आहे.',
            'भगवान श्रीहरि विष्णु और पक्षीराज गरुड़ के संवाद रूप में जीवात्मा की यात्रा, कर्मफल, यमलोक और मोक्ष का विस्तृत वर्णन।',
            'The revered dialogue between Lord Vishnu and Garuda explaining the soul journey, karma, afterlife, Yama realm and ultimate liberation.',
            ?, ?, 1, 2, 1
        )
        ON CONFLICT(slug) DO UPDATE SET
            title_mr = excluded.title_mr,
            title_hi = excluded.title_hi,
            title_en = excluded.title_en,
            subtitle_mr = excluded.subtitle_mr,
            subtitle_hi = excluded.subtitle_hi,
            subtitle_en = excluded.subtitle_en,
            description_mr = excluded.description_mr,
            description_hi = excluded.description_hi,
            description_en = excluded.description_en,
            total_chapters = excluded.total_chapters,
            total_verses = excluded.total_verses,
            free_chapters = 1,
            sort_order = 2,
            is_active = 1
    """, (total_chapters, total_verses))
    conn.commit()
    print("✅ Book metadata updated (is_active = 1, free_chapters = 1).")

    # 2. Insert Chapters
    for ch in GARUDA_CHAPTERS:
        cur.execute("""
            INSERT INTO granth_chapters (
                book_slug, chapter_number,
                name_mr, name_hi, name_en, name_sanskrit,
                summary_mr, summary_hi, summary_en, verses_count
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(book_slug, chapter_number) DO UPDATE SET
                name_mr = excluded.name_mr,
                name_hi = excluded.name_hi,
                name_en = excluded.name_en,
                name_sanskrit = excluded.name_sanskrit,
                summary_mr = excluded.summary_mr,
                summary_hi = excluded.summary_hi,
                summary_en = excluded.summary_en,
                verses_count = excluded.verses_count
        """, (
            "garuda-purana", ch["chapter_number"],
            ch["name_mr"], ch["name_hi"], ch["name_en"], ch["name_sanskrit"],
            ch["summary_mr"], ch["summary_hi"], ch["summary_en"], len(ch["verses"])
        ))

        # 3. Insert Verses
        for v in ch["verses"]:
            cur.execute("""
                INSERT INTO granth_verses (
                    book_slug, chapter_number, verse_number,
                    slok, transliteration, word_meanings,
                    meaning_mr, meaning_hi, meaning_en
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(book_slug, chapter_number, verse_number) DO UPDATE SET
                    slok = excluded.slok,
                    transliteration = excluded.transliteration,
                    word_meanings = excluded.word_meanings,
                    meaning_mr = excluded.meaning_mr,
                    meaning_hi = excluded.meaning_hi,
                    meaning_en = excluded.meaning_en
            """, (
                "garuda-purana", ch["chapter_number"], v["verse_number"],
                v["slok"], v["transliteration"], "",
                v["meaning_mr"], v["meaning_hi"], v["meaning_en"]
            ))

    conn.commit()
    conn.close()
    print(f"🎉 Successfully seeded {total_chapters} chapters and {total_verses} verses of Garuda Purana!")


if __name__ == "__main__":
    target_db = DB_PATH
    if len(sys.argv) > 1:
        target_db = Path(sys.argv[1])
    seed_garuda_purana(target_db)
