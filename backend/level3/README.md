# Level 3

Shipping oversea takes longer. Delays vary by carrier and by distance.
For simplicity sake, the distance is taken from country to country.

## New model:

Carriers add one day on their delivery promise for every [oversea delay] kms separating the origin and delivery country. Oversea delay varies by carrier.

e.g. Colissimo normally ships in 3 business days, but a package from France to Japan will be delivered in 6 business days since Japan is 9500km away from France and Colissimo distance threshold is 3000km

Compute the new expected deliveries taking that extended delay into account. Week ends should still be accounted for. The result should include the oversea delay length in days.

_This is the final level, now would be a good time to tidy up your code and do a last round of refactoring :)_
