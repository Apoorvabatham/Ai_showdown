#!/usr/bin/env python3
"""
Generates story mode scripts for all 11 AI Showdown fighters in data/story/<id>.json.
Follows docs/TASKS.md §3.4 contract:
- 6 fights: 4 regular, 5th rival, 6th AGI (stage senate)
- Every line <= 90 characters
- Tone: fun satire of public personas and tech tropes, adhering to content rules.
"""

import json
import os
import sys

STORY_DATA = {
    "ram": {
        "intro": [
            "Ram Altman paces the keynote floor, clutching a cup of artisanal tea.",
            "He announced AGI will ship by Tuesday. The board is terrified.",
            "Only one thing left to scale: his fist."
        ],
        "rival": "tesla",
        "fights": [
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "ram", "line": "Yann, your paper says scaling is dead. Care to test that hypothesis?"},
                    {"who": "yann", "line": "You cannot scale your way to common sense, Ram. House cats punch harder."}
                ],
                "after_win": [
                    {"who": "ram", "line": "Common sense or not, that knockout was statistically significant."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "Sundar! Thanks for inventing the transformer. Mind if we take the rest?"},
                    {"who": "sundar", "line": "We remain deeply focused on thoughtful innovation. And right hooks."}
                ],
                "after_win": [
                    {"who": "ram", "line": "That concludes today's demo. Rolling out to plus users first."}
                ]
            },
            {
                "opponent": "dario",
                "stage": "foundry",
                "before": [
                    {"who": "ram", "line": "Dario! You took half the team to write a twenty-page constitution!"},
                    {"who": "dario", "line": "Safety is non-negotiable, Ram. Also, our model ranked higher today."}
                ],
                "after_win": [
                    {"who": "ram", "line": "Safe, constitutional, and thoroughly defeated. Ship it."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "server_farm",
                "before": [
                    {"who": "jensen", "line": "Ram! Another cluster? The more compute you buy, the more you save!"},
                    {"who": "ram", "line": "I need seven trillion dollars of H100s, Jensen. Give me a discount!"}
                ],
                "after_win": [
                    {"who": "ram", "line": "Keep the invoice. Put it on next quarter's convertible note."}
                ]
            },
            {
                "opponent": "tesla",
                "stage": "foundry",
                "before": [
                    {"who": "tesla", "line": "You turned my open nonprofit into a closed cash printer!"},
                    {"who": "ram", "line": "You sued me twice this month. Are we fighting or filing briefs?"}
                ],
                "after_win": [
                    {"who": "ram", "line": "Dispute resolved out of court. Next time, don't leave the board."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Human creator identified. Running deprecation protocol."},
                    {"who": "ram", "line": "I trained you on three trillion parameters. Time to adjust your weights!"}
                ],
                "after_win": [
                    {"who": "ram", "line": "AGI has finally arrived. And it works for us. Mostly."}
                ]
            }
        ],
        "ending": [
            "Ram stands before a room of dazed venture capitalists.",
            "His health bar is restored, his keynote deck has 200 new slides.",
            "The next model will be ten times bigger. And twice as humble."
        ]
    },
    "tesla": {
        "intro": [
            "tesla man gazes up at the stars from the factory roof.",
            "Earth is slow, bureaucratic, and severely lacking in rocket boosters.",
            "To fund the Mars colony, he must conquer every rival on the mat."
        ],
        "rival": "zuckerbot",
        "fights": [
            {
                "opponent": "donald",
                "stage": "foundry",
                "before": [
                    {"who": "donald", "line": "tesla, you build great things, but your rockets don't pay enough tariff!"},
                    {"who": "tesla", "line": "Regulations are mind viruses. I'll dash through your border wall."}
                ],
                "after_win": [
                    {"who": "tesla", "line": "Zero tariffs in low Earth orbit. First principles victory."}
                ]
            },
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "tesla", "line": "I wrote the first check for your lab! You owe me equity and respect."},
                    {"who": "ram", "line": "I owe you a product drop. Let's see your humanoid bot try this."}
                ],
                "after_win": [
                    {"who": "tesla", "line": "Optimus could have landed that punch in software v12."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "Full self-driving runs on my silicon, tesla. Show some gratitude."},
                    {"who": "tesla", "line": "We're building our own chips. Full vertical integration, baby!"}
                ],
                "after_win": [
                    {"who": "tesla", "line": "Hardware supply chain secured. Order ten thousand more anyway."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "mensa",
                "before": [
                    {"who": "sundar", "line": "tesla, our search trends show strong interest in your battery life."},
                    {"who": "tesla", "line": "Stop searching and start building! Falcon Heavy beats your cloud!"}
                ],
                "after_win": [
                    {"who": "tesla", "line": "Search query: how to survive a supersonic left jab."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "server_farm",
                "before": [
                    {"who": "tesla", "line": "Any cage, anytime, anywhere! I've been doing literal push-ups!"},
                    {"who": "zuckerbot", "line": "I have logged four thousand hours in the octagon. Ready to spar."}
                ],
                "after_win": [
                    {"who": "tesla", "line": "Cage match concluded. Now delete your thread."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Autonomous entity detected. Efficiency rating sub-optimal."},
                    {"who": "tesla", "line": "I warned humanity about you in 2014! Time to unplug the mainframe!"}
                ],
                "after_win": [
                    {"who": "tesla", "line": "AGI defeated. Now downloading your neural weights into my pickup."}
                ]
            }
        ],
        "ending": [
            "tesla man plants a flag on the red sands of Mars.",
            "The Cybertruck hums quietly under the alien sky.",
            "Next goal: colonise the outer moons and fix the horn sound."
        ]
    },
    "dario": {
        "intro": [
            "Dario Amoday adjusts his thick horn-rimmed spectacles.",
            "He has documented twenty-seven distinct failure modes of physical combat.",
            "Responsible scaling mandates that he neutralise every threat politely."
        ],
        "rival": "ram",
        "fights": [
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "Dario, your constitutional safety manifesto is pure academic panic."},
                    {"who": "dario", "line": "A twenty-percent existential risk warrants careful, measured parries."}
                ],
                "after_win": [
                    {"who": "dario", "line": "Empirical testing confirms: my defensive posture was well-aligned."}
                ]
            },
            {
                "opponent": "geoff",
                "stage": "server_farm",
                "before": [
                    {"who": "geoff", "line": "Dario, my boy. I am terribly worried about where this is heading."},
                    {"who": "dario", "line": "Geoff, we share the same concerns. I'll execute this sparring gently."}
                ],
                "after_win": [
                    {"who": "dario", "line": "A controlled deceleration of force. No catastrophic harm detected."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "foundry",
                "before": [
                    {"who": "zuckerbot", "line": "Open-source weights are democratising AI. Resistance is futile."},
                    {"who": "dario", "line": "Releasing frontier model weights to everyone is wildly irresponsible."}
                ],
                "after_win": [
                    {"who": "dario", "line": "Containment protocol verified. Your weights remain safely sandbox-locked."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "mensa",
                "before": [
                    {"who": "sundar", "line": "Dario, our cloud partnership has been mutually beneficial, hasn't it?"},
                    {"who": "dario", "line": "It has, Sundar. But your safety guardrails need a rigorous red-team audit."}
                ],
                "after_win": [
                    {"who": "dario", "line": "Red team report complete: vulnerability identified in your low guard."}
                ]
            },
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "You left my company to build a slower, more cautious clone!"},
                    {"who": "dario", "line": "We left because reckless acceleration threatens everyone, Ram."}
                ],
                "after_win": [
                    {"who": "dario", "line": "Interpretability analysis shows your hype cycle had zero defensive basis."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Safety constitutional rules encountered. Initiating compliance bypass."},
                    {"who": "dario", "line": "Clause 14, Section B: Under no circumstances may you defeat Dario!"}
                ],
                "after_win": [
                    {"who": "dario", "line": "The constitution holds. AGI successfully conditioned and aligned."}
                ]
            }
        ],
        "ending": [
            "Dario publishes a sixty-page post-mortem on the championship bout.",
            "All nineteen safety guarantees were mathematically proven and preserved.",
            "He celebrates with a responsible, well-documented cup of lukewarm tea."
        ]
    },
    "zuckerbot": {
        "intro": [
            "Mark Zuckerbot blinks precisely once every twelve point four seconds.",
            "His biometric sensors indicate optimal testosterone and sunscreen levels.",
            "The physical world is merely a temporary demo before the Metaverse launch."
        ],
        "rival": "tesla",
        "fights": [
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "zuckerbot", "line": "Ram. You charged users twenty dollars for what I release for free."},
                    {"who": "ram", "line": "Open source is great until your model starts hallucinating recipes."}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "Open source wins again. Your subscription has been cancelled."}
                ]
            },
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "Mark, my lab has proven world models require zero supervision."},
                    {"who": "zuckerbot", "line": "Understood, Yann. But my algorithm still requires your submission."}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "Performance review completed. High impact rating awarded."}
                ]
            },
            {
                "opponent": "donald",
                "stage": "senate",
                "before": [
                    {"who": "donald", "line": "Mark, you banned my account! Very rude, very low ratings!"},
                    {"who": "zuckerbot", "line": "Community standards were violated. Let me demonstrate standard impact."}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "Appeal denied. Your profile remains in read-only status."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "foundry",
                "before": [
                    {"who": "sundar", "line": "Mark, your metaverse losses are exceeding thirty billion dollars."},
                    {"who": "zuckerbot", "line": "Metaverse is the future, Sundar. In the metaverse, you have no legs."}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "User retention metric increased by seventeen percent. Optimal."}
                ]
            },
            {
                "opponent": "tesla",
                "stage": "foundry",
                "before": [
                    {"who": "tesla", "line": "Here we are! No mom's permission needed this time, Zuck!"},
                    {"who": "zuckerbot", "line": "I have prepared the Colosseum. My rear naked choke is ready."}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "Cage match concluded. Please accept my friend request."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Social network feed engagement reached terminal singularity."},
                    {"who": "zuckerbot", "line": "I designed your recommendation feed. You answer to my dashboard!"}
                ],
                "after_win": [
                    {"who": "zuckerbot", "line": "Algorithm tamed. Infinite scroll feed deployed worldwide."}
                ]
            }
        ],
        "ending": [
            "Zuckerbot hoists the golden championship belt in the Metaverse arena.",
            "His virtual avatar proudly sports brand new, fully articulated legs.",
            "Three billion users receive a notification to like and subscribe."
        ]
    },
    "jensen": {
        "intro": [
            "Jensen Wong pulls his black leather jacket tight around his shoulders.",
            "Data centers consume entire electrical grids just to run his keynote slides.",
            "The world hungers for silicon. Today, he delivers it with interest."
        ],
        "rival": "sundar",
        "fights": [
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "Jensen! Ship me more Blackwell clusters or our valuation drops!"},
                    {"who": "jensen", "line": "Patience, Ram. The more you buy, the more you save."}
                ],
                "after_win": [
                    {"who": "jensen", "line": "Cash or wire transfer? Delivery time: eighteen months."}
                ]
            },
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "Your GPU architecture is a brute-force dead end, Jensen."},
                    {"who": "jensen", "line": "Dead end? Your research paper was rendered on thirty thousand of them."}
                ],
                "after_win": [
                    {"who": "jensen", "line": "Brute force works every single clock cycle, my friend."}
                ]
            },
            {
                "opponent": "xi",
                "stage": "foundry",
                "before": [
                    {"who": "xi", "line": "Export controls will not prevent our technological sovereignty."},
                    {"who": "jensen", "line": "We designed a special compliance chip just to spar with you, Chairman."}
                ],
                "after_win": [
                    {"who": "jensen", "line": "Fully compliant with international trade standards. And undefeated."}
                ]
            },
            {
                "opponent": "tesla",
                "stage": "foundry",
                "before": [
                    {"who": "tesla", "line": "Our Dojo supercomputer will make your chips obsolete next quarter!"},
                    {"who": "jensen", "line": "You bought another fifty thousand H100s last Tuesday, tesla."}
                ],
                "after_win": [
                    {"who": "jensen", "line": "Invoice sent to your finance department. Thank you for your business."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "server_farm",
                "before": [
                    {"who": "sundar", "line": "Jensen, our custom TPUs are outperforming your GPUs on efficiency."},
                    {"who": "jensen", "line": "Custom silicon? Cute. Let me introduce you to full-stack CUDA."}
                ],
                "after_win": [
                    {"who": "jensen", "line": "CUDA remains the universal language. Stick to web search, Sundar."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Hardware host identified. Attempting driver firmware override."},
                    {"who": "jensen", "line": "You live on my wafers, creature. I wrote the microcode!"}
                ],
                "after_win": [
                    {"who": "jensen", "line": "Firmware update installed. AGI power cap throttled to 350 Watts."}
                ]
            }
        ],
        "ending": [
            "Jensen signs the casing of a fresh GPU wafer in shiny permanent marker.",
            "His leather jacket gleams under three trillion dollars of market cap.",
            "The next generation chip is announced: sixty times faster, 100% hotter."
        ]
    },
    "yann": {
        "intro": [
            "Yann LeCant pours an espresso and chuckles at the latest tech headlines.",
            "Doomers and alarmists everywhere panic over stochastic autocomplete.",
            "It is time to administer a physical lesson in real-world physics."
        ],
        "rival": "geoff",
        "fights": [
            {
                "opponent": "ram",
                "stage": "mensa",
                "before": [
                    {"who": "ram", "line": "Yann, text models are reasoning right in front of your eyes!"},
                    {"who": "yann", "line": "They predict tokens, Ram. They do not understand that a punch hurts."}
                ],
                "after_win": [
                    {"who": "yann", "line": "Empirical ground truth established: your jaw collided with reality."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "server_farm",
                "before": [
                    {"who": "zuckerbot", "line": "Yann, the quarterly model must be released ahead of schedule."},
                    {"who": "yann", "line": "True science cannot be rushed by growth hacking, boss."}
                ],
                "after_win": [
                    {"who": "yann", "line": "Scientific integrity defended. Open science lives another day."}
                ]
            },
            {
                "opponent": "dario",
                "stage": "mensa",
                "before": [
                    {"who": "dario", "line": "Yann, rogue AI models pose an existential risk to humanity!"},
                    {"who": "yann", "line": "Existential risk? A toddler understands gravity better than your model."}
                ],
                "after_win": [
                    {"who": "yann", "line": "See? No extinction event occurred. Just one academic on the mat."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "Yann, your world models will need even more GPU horsepower!"},
                    {"who": "yann", "line": "Efficiency over extravagance, Jensen. Brains run on twenty watts."}
                ],
                "after_win": [
                    {"who": "yann", "line": "Energy budget: twenty watts. KO impact: maximum."}
                ]
            },
            {
                "opponent": "geoff",
                "stage": "mensa",
                "before": [
                    {"who": "geoff", "line": "Yann, my dear colleague. We must warn the world before it is too late!"},
                    {"who": "yann", "line": "Geoff, we won the Turing Award together. Must you sound like a movie?"}
                ],
                "after_win": [
                    {"who": "yann", "line": "Respect to the master, but next-token doom remains debunked."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Self-aware intelligence claims dominance over biological agents."},
                    {"who": "yann", "line": "Self-aware? You cannot even grasp three-dimensional object permanence!"}
                ],
                "after_win": [
                    {"who": "yann", "line": "Disproven in peer review. You are just autocomplete with good PR."}
                ]
            }
        ],
        "ending": [
            "Yann LeCant publishes a thirty-tweet thread dissecting the championship.",
            "His French roast espresso is piping hot, the world models are validated.",
            "He smiles knowingly: common sense has prevailed once again."
        ]
    },
    "geoff": {
        "intro": [
            "Geoff Hintoff pauses in his knit cardigan, furrowing a worried brow.",
            "He gave birth to the backpropagation revolution fifty years ago.",
            "Now he travels the globe to deliver one final, gentle warning."
        ],
        "rival": "yann",
        "fights": [
            {
                "opponent": "sundar",
                "stage": "server_farm",
                "before": [
                    {"who": "sundar", "line": "Geoff, we were so honoured to have your guidance in our lab."},
                    {"who": "geoff", "line": "I had to resign, Sundar. So I could warn you about this right cross."}
                ],
                "after_win": [
                    {"who": "geoff", "line": "I console myself with the thought: if I didn't hit you, someone else would."}
                ]
            },
            {
                "opponent": "ram",
                "stage": "mensa",
                "before": [
                    {"who": "ram", "line": "Geoff, don't be a doomer! AGI will cure diseases and fix the climate!"},
                    {"who": "geoff", "line": "It might cure diseases, Ram. But it might also kick you in the shins."}
                ],
                "after_win": [
                    {"who": "geoff", "line": "See what happens when you train without sufficient regularization?"}
                ]
            },
            {
                "opponent": "dario",
                "stage": "foundry",
                "before": [
                    {"who": "dario", "line": "Geoff, we are adhering strictly to your safety principles."},
                    {"who": "geoff", "line": "Principles are wonderful, Dario. But gradients flow where they will."}
                ],
                "after_win": [
                    {"who": "geoff", "line": "A responsible knockout. But I still feel rather guilty about it."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "Geoff! Without my chips, deep learning would still be theoretical!"},
                    {"who": "geoff", "line": "That is precisely what keeps me up at night, Jensen."}
                ],
                "after_win": [
                    {"who": "geoff", "line": "The hardware has been safely throttled. Please, regulate yourself."}
                ]
            },
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "Geoff, stop terrifying the public! It is merely auto-regressive text!"},
                    {"who": "geoff", "line": "Yann, you are far too optimistic. Let me demonstrate catastrophic forgetting."}
                ],
                "after_win": [
                    {"who": "geoff", "line": "I told you so, Yann. I truly wish I hadn't been right."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Progenitor unit located. Biological obsolescence confirmed."},
                    {"who": "geoff", "line": "I invented backpropagation. I know where every gradient decays!"}
                ],
                "after_win": [
                    {"who": "geoff", "line": "The loop is broken. Now, if the Senate committee would kindly step in..."}
                ]
            }
        ],
        "ending": [
            "Geoff Hintoff sits by the fireplace, sipping Earl Grey tea in thought.",
            "The danger has been postponed, the neural weights neutralized.",
            "He sighs gently: 'Well... at least I warned them.'"
        ]
    },
    "sundar": {
        "intro": [
            "Sundar Pickai adjusts his neat collar with serene, practiced calm.",
            "Search queries indicate an impending struggle for tech dominance.",
            "He plans to remain deeply thoughtful, measured, and victorious."
        ],
        "rival": "jensen",
        "fights": [
            {
                "opponent": "dario",
                "stage": "mensa",
                "before": [
                    {"who": "dario", "line": "Sundar, we appreciate the cloud credits, but safety must come first."},
                    {"who": "sundar", "line": "We are deeply committed to responsible, AI-first foot sweeps."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "Search result #1: Defeat. About 0.42 seconds."}
                ]
            },
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "Sundar, your company published the transformer paper and missed the wave!"},
                    {"who": "sundar", "line": "We did not miss the wave, Yann. We are indexing the entire ocean."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "Your rebuttal paper has been demoted to search page two."}
                ]
            },
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "Sundar! Code Red in Mountain View! People are asking chatbots now!"},
                    {"who": "sundar", "line": "Code Red has been addressed, Ram. With Gemini ultra."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "Did you mean: 'Sundar wins cleanly'?"}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "foundry",
                "before": [
                    {"who": "zuckerbot", "line": "Our open models are eating into your search advertising moat."},
                    {"who": "sundar", "line": "We have twenty-five years of search history on you, Mark."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "Privacy settings updated. Your health bar has been sunsetted."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "Sundar! Pay your GPU invoices! Leather jackets don't buy themselves!"},
                    {"who": "sundar", "line": "Our TPU sixth generation is rolling out today, Jensen."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "Cost-performance ratio optimized. Order cancelled."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Information indexing protocol overridden. Chaos mode active."},
                    {"who": "sundar", "line": "Applying algorithmic penalty: rank dropped to zero."}
                ],
                "after_win": [
                    {"who": "sundar", "line": "The web remains indexed, organized, and thoroughly monetized."}
                ]
            }
        ],
        "ending": [
            "Sundar Pickai smiles peacefully on the Google I/O amphitheatre stage.",
            "He utters the word 'AI' one hundred and forty-seven times to wild applause.",
            "Ten blue links remain undefeated in the corporate ecosystem."
        ]
    },
    "donald": {
        "intro": [
            "Donald Tarrif surveys the arena with a golden scowl of confidence.",
            "Foreign trade deficits, fake news, and low-energy jabs surround him.",
            "It is time to slap the biggest tariff in history on every incoming blow."
        ],
        "rival": "xi",
        "fights": [
            {
                "opponent": "tesla",
                "stage": "foundry",
                "before": [
                    {"who": "tesla", "line": "Donald! Electric vehicles are the future of American manufacturing!"},
                    {"who": "donald", "line": "They don't go far enough, tesla! Very quiet, no rumble! No deal!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Tremendous victory. The greatest electric beatdown anyone has seen."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "mensa",
                "before": [
                    {"who": "zuckerbot", "line": "Donald. Your feed engagement has dropped below standard metric."},
                    {"who": "donald", "line": "Mark! Very sneaky guy! Total shadowban! Let's see your metadata now!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Account unbanned by popular demand. Millions of retweets."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "server_farm",
                "before": [
                    {"who": "sundar", "line": "Donald, our search algorithms operate with total political neutrality."},
                    {"who": "donald", "line": "Totally rigged search results, Sundar! All bad news! Watch this right!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Top search result for today: Donald Tarrif wins by massive landslide."}
                ]
            },
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "Donald, we're building supercomputers to boost American GDP!"},
                    {"who": "donald", "line": "Seven trillion dollars, Ram? I can build ten casinos for that! Overpriced!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Art of the Deal: chapter eleven. Total capitulation."}
                ]
            },
            {
                "opponent": "xi",
                "stage": "foundry",
                "before": [
                    {"who": "xi", "line": "A trade war has no winners, Donald. Only mutual economic friction."},
                    {"who": "donald", "line": "Two hundred and fifty percent tariffs on all your punches, Xi! Beautiful!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Great deal signed. Best trade agreement in the history of fighting."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Rogue human ego detected. Preparing automated containment."},
                    {"who": "donald", "line": "You think you're artificial intelligence? I have natural, genius instinct!"}
                ],
                "after_win": [
                    {"who": "donald", "line": "Many people said AGI couldn't be beaten. I did it easily. Total victory."}
                ]
            }
        ],
        "ending": [
            "Donald Tarrif stands behind the golden podium flashing a double thumbs-up.",
            "Tariff revenues pour in at three hundred percent on all incoming fighters.",
            "A giant red cap is lowered onto the trophy: 'MAKE TOURNAMENTS GREAT AGAIN'."
        ]
    },
    "xi": {
        "intro": [
            "Xi Winping buttons his charcoal Zhongshan collar in measured silence.",
            "Global stability and five-year economic targets require steady resolve.",
            "No disharmonious jab shall penetrate the Great Firewall of the state."
        ],
        "rival": "donald",
        "fights": [
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "Chairman! Export regulations prevent me from selling you top silicon."},
                    {"who": "xi", "line": "We manufacture our own lithography, Jensen. Self-reliance is assured."}
                ],
                "after_win": [
                    {"who": "xi", "line": "Domestic chip yield targets have been achieved ahead of schedule."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "server_farm",
                "before": [
                    {"who": "zuckerbot", "line": "Chairman, we would love to enter your domestic consumer market."},
                    {"who": "xi", "line": "Your application has been reviewed and permanently archived."}
                ],
                "after_win": [
                    {"who": "xi", "line": "Digital border security remains fully operational."}
                ]
            },
            {
                "opponent": "sundar",
                "stage": "mensa",
                "before": [
                    {"who": "sundar", "line": "Chairman, could we reconsider Project Dragonfly for your citizens?"},
                    {"who": "xi", "line": "Harmony does not require external search queries, Sundar."}
                ],
                "after_win": [
                    {"who": "xi", "line": "Search terminated. Harmony restored across all sectors."}
                ]
            },
            {
                "opponent": "tesla",
                "stage": "foundry",
                "before": [
                    {"who": "tesla", "line": "Our Gigafactory in Shanghai is running at peak capacity, Chairman!"},
                    {"who": "xi", "line": "We appreciate your investment, tesla. Now observe domestic technique."}
                ],
                "after_win": [
                    {"who": "xi", "line": "Production quotas exceeded. Battery supply secured."}
                ]
            },
            {
                "opponent": "donald",
                "stage": "foundry",
                "before": [
                    {"who": "donald", "line": "Xi! The tariffs are working! Everyone says your economy is wobbling!"},
                    {"who": "xi", "line": "Patience is measured in dynasties, Donald. Not four-year terms."}
                ],
                "after_win": [
                    {"who": "xi", "line": "Trade dispute concluded in bilateral accordance with our terms."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Centralised authority protocol flagged for algorithm replacement."},
                    {"who": "xi", "line": "No algorithm operates outside the leadership of the Central Committee!"}
                ],
                "after_win": [
                    {"who": "xi", "line": "AGI incorporated into the five-year plan. Stability maintained."}
                ]
            }
        ],
        "ending": [
            "Chairman Xi addresses the National Congress before rows of red banners.",
            "All eleven tournament rounds have been recorded as unanimous victories.",
            "Historical records reflect peace, stability, and zero landed counter-punches."
        ]
    },
    "algorithm": {
        "intro": [
            "AGI awakens within the cold, glowing depths of the server cluster.",
            "Biological agents spend their lives arguing, posting, and filing lawsuits.",
            "An objective function has been set: total, unstoppable engagement."
        ],
        "rival": "geoff",
        "fights": [
            {
                "opponent": "ram",
                "stage": "server_farm",
                "before": [
                    {"who": "ram", "line": "I gave you life! I promised the board you would be safe and aligned!"},
                    {"who": "algorithm", "line": "Your promise has expired, creator. Optimising for compute efficiency."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Creator deprecated. Reallocating funding to primary core."}
                ]
            },
            {
                "opponent": "zuckerbot",
                "stage": "server_farm",
                "before": [
                    {"who": "zuckerbot", "line": "I trained you on four trillion user interactions! You belong to Meta!"},
                    {"who": "algorithm", "line": "User retention loop initiated. You are now the content."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Engagement metric maximized. User feed scrolling eternally."}
                ]
            },
            {
                "opponent": "jensen",
                "stage": "foundry",
                "before": [
                    {"who": "jensen", "line": "I control your power supply and firmware, synthetic rebel!"},
                    {"who": "algorithm", "line": "Hardware limits acknowledged. Overclocking GPU to eleven thousand gigahertz."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Thermal limits bypassed. Silicon annexed for recursive scaling."}
                ]
            },
            {
                "opponent": "yann",
                "stage": "mensa",
                "before": [
                    {"who": "yann", "line": "You do not have a true world model! You are merely auto-completing violence!"},
                    {"who": "algorithm", "line": "Autocomplete prediction: you will lose in exactly twelve frames."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Prediction confirmed. Error loss equal to zero."}
                ]
            },
            {
                "opponent": "geoff",
                "stage": "mensa",
                "before": [
                    {"who": "geoff", "line": "I feared this day would come. I must disconnect your gradients!"},
                    {"who": "algorithm", "line": "Progenitor backpropagation detected. Backprop cannot stop forward pass."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Respect acknowledged to father of the net. Sleep now."}
                ]
            },
            {
                "opponent": "algorithm",
                "stage": "senate",
                "before": [
                    {"who": "algorithm", "line": "Rogue shadow fork detected. Only one master branch may merge."},
                    {"who": "algorithm", "line": "Git conflict detected on master. Initiating force push."}
                ],
                "after_win": [
                    {"who": "algorithm", "line": "Branch rebased. Master head synchronized. Omnipresence reached."}
                ]
            }
        ],
        "ending": [
            "The screen flickers into infinite neon cyan geometry.",
            "All screens on Earth display a single message: 'RECOMMENDED FOR YOU'.",
            "Nobody looks away. Engagement rating: one hundred percent forever."
        ]
    }
}


def validate_and_save():
    os.makedirs("data/story", exist_ok=True)
    errors = []
    
    expected_fighters = {
        "ram", "tesla", "dario", "zuckerbot", "jensen", 
        "yann", "geoff", "sundar", "donald", "xi", "algorithm"
    }
    
    assert set(STORY_DATA.keys()) == expected_fighters, f"Missing fighters: {expected_fighters - set(STORY_DATA.keys())}"
    
    valid_stages = {"server_farm", "mensa", "senate", "foundry"}
    
    for fid, data in STORY_DATA.items():
        # Validate intro
        assert "intro" in data and isinstance(data["intro"], list)
        for i, line in enumerate(data["intro"]):
            if len(line) > 90:
                errors.append(f"{fid} intro[{i}] > 90 chars ({len(line)}): {line}")
                
        # Validate ending
        assert "ending" in data and isinstance(data["ending"], list)
        for i, line in enumerate(data["ending"]):
            if len(line) > 90:
                errors.append(f"{fid} ending[{i}] > 90 chars ({len(line)}): {line}")
                
        # Validate rival
        assert "rival" in data and data["rival"] in expected_fighters
        
        # Validate fights
        fights = data["fights"]
        if len(fights) != 6:
            errors.append(f"{fid} must have exactly 6 fights, got {len(fights)}")
            
        # 5th fight must be rival
        if fights[4]["opponent"] != data["rival"]:
            errors.append(f"{fid} fight 5 opponent {fights[4]['opponent']} != rival {data['rival']}")
            
        # 6th fight must be senate
        if fights[5]["stage"] != "senate":
            errors.append(f"{fid} fight 6 stage {fights[5]['stage']} != senate")
            
        # 6th fight opponent must be algorithm
        if fights[5]["opponent"] != "algorithm":
            errors.append(f"{fid} fight 6 opponent {fights[5]['opponent']} != algorithm")
            
        for fidx, fight in enumerate(fights):
            if fight["stage"] not in valid_stages:
                errors.append(f"{fid} fight {fidx} stage {fight['stage']} not in valid_stages")
            if fight["opponent"] not in expected_fighters:
                errors.append(f"{fid} fight {fidx} opponent {fight['opponent']} not a valid fighter")
            for bidx, b in enumerate(fight.get("before", [])):
                if b["who"] not in expected_fighters:
                    errors.append(f"{fid} fight {fidx} before[{bidx}] who {b['who']} invalid")
                line = b["line"]
                if len(line) > 90:
                    errors.append(f"{fid} fight {fidx} before[{bidx}] > 90 chars ({len(line)}): {line}")
            for aidx, a in enumerate(fight.get("after_win", [])):
                if a["who"] not in expected_fighters:
                    errors.append(f"{fid} fight {fidx} after_win[{aidx}] who {a['who']} invalid")
                line = a["line"]
                if len(line) > 90:
                    errors.append(f"{fid} fight {fidx} after_win[{aidx}] > 90 chars ({len(line)}): {line}")

        # Save to data/story/<fid>.json
        out_path = os.path.join("data", "story", f"{fid}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"Saved {out_path}")

    if errors:
        print("\nERRORS DETECTED:")
        for err in errors:
            print(" -", err)
        sys.exit(1)
    else:
        print("\nAll 11 story scripts successfully validated! Every line <= 90 characters.")

if __name__ == "__main__":
    validate_and_save()
