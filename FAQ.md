Frequently Asked Questions / Common Comments
============================================

I get emailed about these so often I decided it's time to make a page
about it. More to come as it happens / as I remember.


But AI is the future! You can't stop it!
----------------------------------------

[First tech bubble, huh?](https://www.wheresyoured.at/longcon/)

Seriously, (a) these AI things don't really work, and (b) they have
other significant problems and are causing real harm to people with
little benefit.

I am unsure about effectiveness; but I can see the way crawlers have
reacted, changed their patterns since January 2025, that they see this
as a problem. I don't know if they think tarpitting and poisoning are
a minor nuisance or an existential threat. They are definitely
reacting though.

And if we keep pushing, we can make 
[Sam Altman](https://dair-community.social/@timnitGebru/114230667735623641)
or [Elon Musk](https://www.newsweek.com/elon-musk-tesla-protest-hate-2046937)
cry. And who doesn't want that? Sad billionaires are funny.


Hasn't this been done before?
-----------------------------

I never claimed to be the first. I remember infinite websites from the
early 2000's; my inspiration is the anti-spam tarpitting that was briefly
popular a short time after. I've since been made aware of some others,
who even predated Nepenthes, using these same tactics against AI crawlers.

Nepenthes is simply the first that went viral for this particular
trend.


This is easy for crawlers to detect!
------------------------------------

At the time I released Nepenthes v1.0, I had logged nearly 30 million
hits from Facebook, 5 million from Claude, 3 million from Google, and
several hundred thousand from OpenAI.

If it's easy, at least as of January 2025, they weren't even trying.


Doesn't this just increase energy consumption?
----------------------------------------------

On the AI side, probably. I hope so, anyway. As of now (March 2025)
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
your wallet, but text is so much smaller that multimedia it has not been
an issue.


Isn't this illegal?!
--------------------

No, it's not illegal. I made a website. They send fully HTTP compliant
requests to it, it responds, like all other websites. If that's a
problem for them, they should simply stop sending more requests. (Spoiler
alert: They don't.)

If you call Grampa Simpson trying to sell him something, and he just
talks your ear off without letting you get a word in, who's fault is it
if you stay on the line?


Why not use an LLM to generate the bullshit that gets sent back?
----------------------------------------------------------------

Markov Models are very simple - they get good enough quality for poison
and use very little CPU by comparison to AI techniques.

Remember, all an LLM does, is try to predict the next most likely word.
Which is also what a Markov model does. The output of a Markov babbler
is stastically identical to the input the model was trained on - by
definition. The semantic information was discarded on the way, but IMHO
that's a feature for this use case.
