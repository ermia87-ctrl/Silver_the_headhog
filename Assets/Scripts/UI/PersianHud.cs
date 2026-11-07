using UnityEngine;
using UnityEngine.UI;
namespace PersianRunner
{
    public sealed class PersianHud : MonoBehaviour
    {
        [SerializeField] Text scoreText;
        int score;
        void OnEnable() => Collectible.Collected += AddScore;
        void OnDisable() => Collectible.Collected -= AddScore;
        void Start() => Refresh();
        void AddScore() { score += 10; Refresh(); }
        void Refresh() { if (scoreText) scoreText.text = "امتیاز: " + score.ToString("N0"); }
    }
}