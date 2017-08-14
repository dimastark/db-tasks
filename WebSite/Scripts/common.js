Region = function (data) {
    var self = this;
    self.code = data.SS;
    self.name = data.FULLNAME;
    self.index = data.INDEX;
}

Locality = function (data) {
    var self = this;
    self.code = data.CODE;
    self.name = data.FULLNAME;
    self.index = data.INDEX;
}

Street = function (data) {
    var self = this;
    self.code = data.YYYY;
    self.name = data.FULLNAME;
    self.index = data.INDEX;
    self.PPP = data.PPP;
}

House = function (data) {
    var self = this;
    self.code = data && data.HHHH ? data.HHHH : '0000';
    self.name = data ? data.NAME : null;
    self.index = data ? data.INDEX : null;
}

User = function (data) {
    var self = this;
    self.fullname = data.NAME + " " + data.SECONDNAME + " " + data.SIRNAME;
    self.address = self.fullname + ", " + data.ADDRESS;
    self.login = data.LOGIN;
}

// функция находит подходящую строку из таблицы DOMA для данного номера дома
var findDomaStringForHouseName = function (houseName, domaStrings) {
    console.log(domaStrings);
    console.log(houseName);
    houseName = houseName.toLowerCase();
    var houseNum = Number(houseName);
    // цикл по всем строкам в DOMA, соответствующим указанной улице
    for (var i = 0; i < domaStrings.length; i++) {
        var currentRecord = domaStrings[i];
        var pieces = currentRecord.NAME.toLowerCase().split(',');
        // цикл по всем компонентам строки в DOMA (подстрокам, разделённым запятыми)
        for (var j = 0; j < pieces.length; j++) {
            var piece = pieces[j].trim();

            ['влд', 'строение', 'стр', 'двлд', 'сооружение'].forEach(function (prefix) {
                if (piece.startsWith(prefix)) {
                    piece = piece.substring(prefix.length);
                }
            });

            if (piece.indexOf('-') === -1) { // если нет дефиса, значит не диапазон
                if (piece === houseName) {
                    return currentRecord;
                }
            } else {
                // если номер не является числом (напр. 2Ж), то по диапазону не ищем
                if (Number.isNaN(houseNum)) {
                    continue;
                }
                // если в подстроке присутствует дефис, значит это интервал
                var leftNumStartIdx = piece.indexOf('(') + 1;
                var rightNumEndIdx = piece.indexOf(')');
                if (rightNumEndIdx < 0) {
                    rightNumEndIdx = piece.length;
                }

                var dashIdx = piece.indexOf('-');
                var left = Number(piece.substring(leftNumStartIdx, dashIdx));
                var right = Number(piece.substring(dashIdx + 1, rightNumEndIdx));

                var even = piece[0] === 'Ч';
                var odd = piece[0] === 'Н';
                var numIsEven = houseNum % 2 === 0;

                if (houseNum >= left && houseNum <= right
                    && ((even && numIsEven) || (odd && !numIsEven) || (!odd && !even))) {
                    return currentRecord;
                }
            }
        }
    }
    return false;
}

var startEditHouse = function (self) {
    self.editHouse(true);
}

var endEditHouse = function (self) {
    self.editHouse(false);
    console.log('Поиск записи для дома: ' + self.houseName());

    $('#spinner').spin();
    // запрашиваем список записей DOMA для указанной улицы
    $.getJSON("/Account/House?street=" + self.locality().code + self.street().code, function (data) {
        var foundRecord = findDomaStringForHouseName(self.houseName(), data);
        if (foundRecord) {
            self.house(new House({
                NAME: self.houseName(),
                HHHH: foundRecord.HHHH,
                INDEX: foundRecord.INDEX
            }));
        } else {
            alert("Bad House");
        }
    }).done(function () {
        $('#spinner').spin(false);
    });

    self.flatName('');

}



var applyCommon = function (self) {
    self.startEditHouse = startEditHouse.bind(this, self);
    self.endEditHouse = endEditHouse.bind(this, self);
}