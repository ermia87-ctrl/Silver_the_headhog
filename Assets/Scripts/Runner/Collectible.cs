using UnityEngine;
namespace PersianRunner
{
    public sealed class Collectible : MonoBehaviour
    {
        public static System.Action Collected;
        void Update() => transform.Rotate(0, 150f * Time.deltaTime, 0, Space.World);
        void OnTriggerEnter(Collider other)
        {
            if (!other.GetComponent<RunnerController>()) return;
            Collected?.Invoke();
            Destroy(gameObject);
        }
    }
}