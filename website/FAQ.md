Frequently Asked Questions / Common Comments
============================================

I get emailed about these so often I decided it's time to make a page
about it. More to come as it happens / as I remember.


But AI is the future!
---------------------

[First tech bubble, huh?](https://www.wheresyoured.at/longcon/)

Seriously, (a) these AI things [don't really work](https://pivot-to-ai.com/2025/05/13/if-ai-is-so-good-at-coding-where-are-the-open-source-contributions/)
, and (b) they have significant ethical and [ecological](https://www.greenmatters.com/big-impact/how-much-water-does-ai-use)
problems and (c) are causing [real harm](https://www.rollingstone.com/culture/culture-features/ai-spiritual-delusions-destroying-human-relationships-1235330175/)
to people with [little benefit.](https://www.livescience.com/technology/artificial-intelligence/using-ai-reduces-your-critical-thinking-skills-microsoft-study-warns)

But what about the [economic](https://www.wheresyoured.at/wheres-the-money/)
effects? I'll just quote Brian Merchant, who seems to be saying,
[That doesn't look good either!](https://www.bloodinthemachine.com/p/the-ai-bubble-is-so-big-its-propping) 

>" It’s to the point that we’re well past dot com boom levels of investment, and, as Kedrosky points out, approaching railroad-levels of investment, last seen in the days of the robber barons.
>
> I have no idea what’s going to happen next. But if AI investment is so massive that it’s quite actually helping to prop up the US economy in a time of growing stress, what happens if the AI stool does get kicked out from under it all? "


You can't stop AI!
------------------

I am unsure about effectiveness of Nepenthes; but I can see the way crawlers have
reacted, changed their patterns since January 2025, that they see this
as a problem. I don't know if they think tarpitting and poisoning are
a minor nuisance or an existential threat. They are definitely
reacting though.

And there's good reason for them to react: none of these companies doing actual
AI stuff, as opposed to selling hardware for AI stuff, are profitable (see above.)
Nepenthes raises their costs.

And if we keep pushing, we can make 
[Sam Altman](https://dair-community.social/@timnitGebru/114230667735623641)
or [Elon Musk](https://www.newsweek.com/elon-musk-tesla-protest-hate-2046937)
cry. And who doesn't want that? Sad billionaires are funny.


Hasn't this been done before?
-----------------------------

I never claimed to be the first. I remember infinite websites from the
early 2000's; my inspiration is the [anti-spam SMTP tarpitting](https://www.benzedrine.ch/relaydb.html)
that was briefly
popular a short time after. I've since been made aware of some others,
who even predated Nepenthes, using these same tactics against AI crawlers.

Nepenthes is simply the first that went viral for this particular
use case.

Is this actually effective at stopping crawlers?
------------------------------------------------

Honestly, it varies. I've gotten reports from multiple site operators, that
Nepenthes saved them from going offline. Sometimes the crawler gets contained;
recently I'm hearing that their site stops being crawled after Nepenthes 
slows them down enough.

I've also heard reports of crawlers doubling down, becoming even more overwhelming
in response. These unlucky ones usually go offline, or switch to something like
[Anubis](https://anubis.techaro.lol/).

I think the differentiator is how badly the crawler wants your data. Sites considered
medium or low value to scrape, Nepenthes is quite effective at getting them to leave
you alone. If you have something they consider very high value: well.. 

The sad truth is, [If a dedicated adversary has resources on par with all Azure
at their disposal](https://vercel.com/blog/the-rise-of-the-ai-crawler), and/or
[is willing to use quasi-legal botnets](https://social.wildeboer.net/@jwildeboer/114358972839151578) to attack you,
it becomes a matter of who has more cash to spend - and until the bubble finally
pops, OpenAI and Anthropic definitely have more than you.


This is easy for crawlers to detect!
------------------------------------

At the time I released Nepenthes v1.0, I had logged nearly 30 million
hits from Facebook, 5 million from Claude, 3 million from Google, and
several hundred thousand from OpenAI.

If it's easy, at least as of January 2025, they weren't even trying.


Doesn't this just increase energy consumption?
----------------------------------------------

On the AI side, probably. I hope so, anyway. Again,
none of these companies are profitable: Adding to their costs will
hopefully cause them to fail sooner. There's only so much cash an
investor will put in without a return before they give up and pull
funding.

A rational investor, anyway. I'm sure some aren't, thankfully those 
tend to go bankrupt.

As for my energy consumption: my busiest Nepenthes instance was using
about the same as a Raspberry Pi 3. Meh.

As I was quoted in Ars Technica, and I stand by this: "If I do nothing, 
AI models, they boil the planet. If I switch this on, they boil the
planet. How is that my fault?"


Doesn't this cost you a lot of money in bandwidth overages?
-----------------------------------------------------------

No.

We live in a era with multi-hundred gigabit internet backbones.

Bandwidth is cheap now. Typically a terabyte of transfer is included
in a $5/month VPS plan. Thank video streaming services for pushing so
much high def that capacity got overbuilt.

I suppose you could tune for maximum throughput and do some damage to 
your wallet, but text is so much smaller than multimedia it has not been
an issue.


Won't crawlers adapt by discarding slow websites?
-------------------------------------------------

That'd be great! Please do that!


Isn't this illegal?!
--------------------

No, it's not illegal. I made a website. They send HTTP requests to it,
it responds with fully HTTP complaint responses like all other websites. 
If that's a problem for them, they should simply stop sending more requests.
(Spoiler alert: They don't.)

If you call Grampa Simpson trying to sell him something, and he just
talks your ear off without letting you get a word in, who's fault is it
if you stay on the line? Did Grampa do something illegal by being terrible
at conversation?


Why not use an LLM to generate the bullshit that gets sent back?
----------------------------------------------------------------

Markov Models are very simple - they get good enough quality for poison
and use very little CPU by comparison to AI techniques.

Remember, all an LLM does, is try to predict the next most likely word.
Which is also what a Markov model does. The output of a Markov babbler
is stastically identical to the input the model was trained on - by
definition. The semantic information was discarded on the way, but IMHO
that's a feature for this use case.


This is useless, the AI companies just filter out garbage data!
---------------------------------------------------------------

Then why are they spending so much time and resources pulling anything they can
from the internet, often so fast it overwhelms small websites? Why are they paying
money to crawl whatever they find, and then paying money to store it, only to throw
it all out?

[I want them to stop crushing websites.](https://arstechnica.com/ai/2025/03/devs-say-ai-crawlers-dominate-traffic-forcing-blocks-on-entire-countries/)
Even if the models survive the poison, that alone would be a win.

