/// The example job shown on the sign-in identity surface.
///
/// Approved at Gate 0 and re-confirmed at Gate 3: the screen may show exactly
/// one **labelled** example job so a first-time admin can see what the product
/// does. It is never presented as the user's own data, and it is not live.
///
/// These are data-like proper nouns and numbers, not translatable copy, so they
/// live as constants rather than `l10n` keys. They are always rendered LTR so
/// bidi never reorders a plate or a model name.
library;

const String exampleVehicle = '2023 Porsche 911 GT3';
const String examplePlate = 'DXB 48291';
const String exampleCustomer = 'Rashid Al Mansoori';
const String exampleTechnician = 'Karim Ahmed';
const String exampleInitials = 'KA';
const int exampleDone = 18;
const int exampleTotal = 24;
const int examplePercent = 75;
const int exampleStartedMinutes = 45;
