# Маппинг полей: Тарифы → Услуги

Перегрузка элементов справочника **Тарифы** (`Catalog.RoomRates`) в справочник **Услуги** (`Catalog.Services`).

Реализовано обработкой `DataProcessor.TransferRoomRatesToServices`. Пустой список групп переносит все тарифы. Заполненный список переносит выбранные группы и всё, что лежит внутри них. Группы-родители выше отбора тоже переносятся, чтобы сохранилась иерархия.

Оба справочника иерархические (группы и элементы). Владельца нет.

| | Тарифы | Услуги |
|---|---|---|
| Код | строка, фиксированная, 25, уникальный, автонумерация выключена | строка, фиксированная, 11, уникальный, автонумерация включена |
| Наименование | строка, 50 | строка, 150 |

## Ключ соответствия элементов

Ключ — UUID ссылки тарифа. Услуга ищется и создаётся как `Catalogs.Services.GetRef(Тариф.UUID())`, для нового элемента вызывается `SetNewObjectRef`. Повторный запуск обновляет эту же услугу.

| Тарифы | Услуги | Правило |
|---|---|---|
| `Ref.UUID()` | `Ref` услуги | Ключ поиска и идентификатор новой услуги |
| `Code` — Код | `Code` — Код | У новой услуги копируется, если длина без хвостовых пробелов не больше 11 и код свободен. Иначе назначается новый код. У уже существующей услуги код не меняется |
| `Parent` — Группа | `Parent` — Родитель | `Catalogs.Services.GetRef(ГруппаТарифа.UUID())`. Группы записываются раньше элементов |

`ExternalCode` услуги не заполняется: связь хранится в UUID ссылки.

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

Для новой услуги (не группы) обработка ставит `IsRoomRevenue` = Истина. В тарифе такого реквизита нет. При повторном запуске уже записанное значение не меняется.
