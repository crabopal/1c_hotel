# Маппинг полей: Тарифы → Услуги

Перегрузка элементов справочника **Тарифы** (`Catalog.RoomRates`) в справочник **Услуги** (`Catalog.Services`).

Оба справочника иерархические (группы и элементы). Владельца нет.

| | Тарифы | Услуги |
|---|---|---|
| Код | строка, фиксированная, 25, уникальный, автонумерация выключена | строка, фиксированная, 11, уникальный, автонумерация включена |
| Наименование | строка, 50 | строка, 150 |

## Ключ соответствия элементов

| Тарифы | Услуги | Правило |
|---|---|---|
| `Code` — Код | `ExternalCode` — Код во внешней системе | Всегда. Полный код тарифа (до 25 символов) помещается в строку 36 и сохраняет связь после перегрузки. |
| `AccommodationService` — Услуга - проживание | ссылка на элемент `Services` | Если реквизит заполнен, обновлять эту услугу. Иначе создавать новый элемент. |
| `Code` — Код | `Code` — Код | Копировать, когда длина кода без хвостовых пробелов не больше 11 и такой код в услугах свободен. Иначе оставить автонумерацию услуг, полный код остаётся в `ExternalCode`. |

Группы переносятся раньше элементов. `Parent` тарифа указывает на группу тарифов, поэтому в услугу пишется группа услуг, созданная из той же группы тарифа (по `ExternalCode` = код группы тарифа).

## Прямое копирование

Имя реквизита совпадает, тип совместим.

| Тарифы | Услуги | Тип | Примечание |
|---|---|---|---|
| `Description` — Наименование | `Description` — Наименование | Строка | 50 → 150, обрезка не нужна |
| `DeletionMark` — Пометка удаления | `DeletionMark` — Пометка удаления | Булево | |
| `IsFolder` — Это группа | `IsFolder` — Это группа | Булево | |
| `Parent` — Группа | `Parent` — Родитель | Ссылка на свою группу | Через ключ соответствия групп, см. выше |
| `DescriptionTranslations` — Переводы наименования на различные языки | `DescriptionTranslations` — Переводы наименования на различные языки | Строка неограниченная | |
| `SortCode` — Порядок сортировки | `SortCode` — Порядок сортировки | Число 6.0, неотрицательное | |
| `QuantityCalculationRule` — Правило вычисления количества по умолчанию | `QuantityCalculationRule` — Правило вычисления количества | `CatalogRef.QuantityCalculationRules` | |
| `Remarks` — Примечания | `Remarks` — Примечания | Строка неограниченная | |
| `Hotel` — Гостиница | `Hotel` — Гостиница | `CatalogRef.Hotels` | |

## Смысловое соответствие

Имена разные, тип совместим, смысл совпадает.

| Тарифы | Услуги | Тип | Правило |
|---|---|---|---|
| `IsOnlineRate` — Тариф доступен on-line | `OnlineAvaliable` — Доступна онлайн | Булево | Копировать значение. Имя приёмника в метаданных с опечаткой: `OnlineAvaliable`. |
| `ServicesIncludedDescription` — Описание услуг включенных в тариф для печати | `Composition` — Состав услуги | Строка неограниченная | Копировать текст описания состава. |

## Реквизиты тарифа без приёмника

В `Services` нет реквизита того же типа и смысла. При перегрузке элемента услуги эти значения не записываются.

`RoomRateType`, `PriceTagType`, `ServicePackage`, `DateValidFrom`, `DateValidTo`, `Calendar`, `PeriodInHours`, `DurationCalculationRuleType`, `ReferenceHour`, `FirstDayEndsAtReferenceHourTime`, `RateChargeDirection`, `DefaultCheckInTime`, `DefaultCheckOutTime`, `DefaultDuration`, `IsRackRate`, `IsHiddenRateForAuthorizedClients`, `IsRateForCRS`, `Company`, `RoomRateServiceGroup`, `BasedOnRoomRate`, `BasedOnPriceTag`, `Discount`, `DiscountType`, `OnlineDiscount`, `UpgradeDiscount`, `DiscountServiceGroup`, `RoundPrice`, `RoundPriceDigits`, `RoundPriceServiceGroup`, `NoDiscounts`, `NoAgentCommission`, `MaxAgentCommission`, `IsComplimentary`, `IsHouseUse`, `IsStateContract`, `DoNotPrintRate`, `ReservationConditionsShort`, `ReservationConditionsOnline`, `ReservationConditions`, `PaymentMethodCodesAllowedOnline`, `MarketingCode`, `SourceOfBusiness`, `ClientType`, `ClientTypeConfirmationText`, `HotelProductType`, `UseNewFolioIfCheckOutDateChanged`, `RoomRatesApproved`, `DoNotRefillOccupationPercentsAfterInHouseRoomChange`, `MLOSIsBlocking`, `Allotment`, `FeeTerms`, `IdentificationCardType`, `ContractType`, `EarlyCheckInService`, `LateCheckOutService`, `CloseOfPeriodDoChargeServices`, `RackRate`, `Author`, `CreateDate`, `LimitsLastChangeDate`, `ShowUpgrades`, `ReservationRemarksAmenity`, `ReservationHousekeepingRemarksAmenity`, `ReservationRemarksTaskArea`, `ReservationHousekeepingRemarksTaskArea`, `DefaultCurrency`, `UsePricesFromCalendar`, `RoomTypeChangeUpdatesPriceCalculationDate`, `MealBoardTermsIsMandatory`, `Parameters`, `DoNotMergeTouristTaxBaseToTheMainRoomGuest`, `TouristTaxService`, `TouristTaxAddToRate`, `TouristTaxSubtractFromRateIfExemption`.

`EarlyCheckInService`, `LateCheckOutService` и `TouristTaxService` уже ссылаются на услуги. Это отдельные элементы услуг, а не реквизиты создаваемой услуги проживания.

## Табличные части

| Тарифы | Услуги | Правило |
|---|---|---|
| `ServicePackages` — Пакеты услуг (`ServicePackage`, `PacketPriceIsIncludedInRoomRate`) | нет табличной части с пакетами услуг | Не переносится |
| `Formulas` — Формулы (устаревшая; вместо неё документы «Спецификация формул тарифов») | нет | Не переносится |
| нет | `ServiceItems` — Позиции меню | Источника нет, таблица остаётся пустой |

## Реквизиты услуги без источника

Остаются значениями по умолчанию нового или уже существующего элемента: `GroupByDescriptionTranslations`, `Unit`, `UnitTranslations`, `GetUnitFromRule`, `AllowChangePrice`, `RecalculatePriceWhenSumChanged`, `IsRoomRevenue`, `RoomRevenueAmountsOnly`, `IsInPrice`, `IsResourceRevenue`, `DoNotGroupIntoRoomRateOnPrint`, `SplitToSeparateSettlements`, `DoNotExportToTheAccountingSystem`, `IsNotInvoiced`, `BreakdownListFormula`, `ServiceRegistrationIsTurnedOn`, `MaxOneServicePerDayIsAllowed`, `ServiceType`, `PaymentSection`, `TaxationSystem`, `ChargePerPerson`, `IsStockArticle`, `IsAgentService`, `Principal`, `PrincipalType`, `IsNotOurService`, `IsHotelProductService`, `IsPricePerMinute`, `ResourceType`, `Resource`, `BoundService`, `ChequeItemType`, `HideIntoServiceOnPrint`, `IsGiftCertificate`, `BonusPaymentsNotAllowed`, `BarCode`, `IsResortFee`, `AvailableQuantity`, `DepartmentCode`, `CorrectionService`, `NoPrepaymentIsAllowed`, `CashRegisterItemCode`, `ChargeToEachGuestSeparately`, `AlwaysChargeInAdvance`, `IsQuantitativeAccounting`, `InvoiceGroupingName`, `UseMarking`, `UpgradeFromTerms`, `UpgradeToTerms`, `ExciseDutyType`, `Volume`, `MarkingCodeType`, `ChargeOnCreditIsAllowed`.

Для услуги, созданной из тарифа проживания, отдельно от маппинга полей имеет смысл выставить `IsRoomRevenue` = Истина. В тарифе такого реквизита нет.
