using System;
using UnityEngine;
namespace PersianRunner
{
    [Serializable]
    public class CharacterEntry
    {
        public string id;
        public string displayNameFa;
        [TextArea] public string notes;
        public GameObject licensedModelPrefab;
    }

    [CreateAssetMenu(menuName = "Persian Runner/Character Roster")]
    public sealed class CharacterRoster : ScriptableObject
    {
        public CharacterEntry[] characters =
        {
            new CharacterEntry { id = "hero_blue", displayNameFa = "قهرمان آبی", notes = "جایگاه مدل اصلی؛ مدل و انیمیشن باید مجوز استفاده داشته باشد." },
            new CharacterEntry { id = "hero_silver", displayNameFa = "قهرمان نقره‌ای", notes = "جایگاه شخصیت دوم؛ مدل مجاز را در Inspector متصل کن." },
            new CharacterEntry { id = "movie_hero", displayNameFa = "قهرمان سینمایی", notes = "جایگاه مدل مستقل با مجوز معتبر؛ دارایی رسمی فیلم همراه پروژه نیست." }
        };
    }
}